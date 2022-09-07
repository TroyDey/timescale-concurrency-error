-- (c) Copyright 2022 Hewlett Packard Development LP

-- This code is a modified and simplified version of the database schema for Promscale
-- https://github.com/timescale/promscale
-- Major changes
-- * metrics category: Add a category to metrics since we have metrics that are related and behave similary
-- * Remove various users and schemas since we are not delivering this as a generic product, but as a tightly integrated component of HPCM
-- * Remove the label_key table since we don't have a use for this
-- * Remove matcher_operators and json related functions since we are not using these
-- * Add series_lookup table to quickly translate label sets to their corresponding series
-- * Convert to work with UNIX epoch timestamps of varying resolutions
-- * Delay and stagger start of compression and retention jobs
-- * Add convenience methods for managing groups of data nodes
-- * Create jobs for distributed hypertable maintenance
-- * Other simplifications


-- Create a special type to clearly indicate our intent
-- for function arguments and return type
CREATE DOMAIN label_array AS int[] NOT NULL;

-- Join table from metric tables to label table
-- Metric table rows will store the series id
-- To avoid having to constantly add and remove columns and avoid an explosion of 
-- the number of rows in this table we store the lables we will be joining to as an 
-- ordered array of label ids in the labels column. The order is defined in label_key_position
CREATE TABLE IF NOT EXISTS series (
    id int NOT NULL,
    metric_id int NOT NULL,
    labels label_array NOT NULL, --labels are globally unique because of how partitions are defined
    delete_epoch bigint NULL DEFAULT NULL -- epoch after which this row can be deleted, won't use this right away
) PARTITION BY LIST(metric_id); -- partition by metric_id, partitions will be manually attached

-- Use an inverted index on the lables
-- This will treat each element of the index as a keyword
-- allowing efficient lookup of rows on label id
CREATE INDEX IF NOT EXISTS series_labels_id ON series USING GIN (labels);

-- The id for the series will be managed manually
CREATE SEQUENCE IF NOT EXISTS series_id;

-- lables (aka tags) stores metadata/context about metrics
-- Example: "DeviceSpecificContext": "local" for slingshot metrics
-- Another example is the location property for slingshot metrics which contains
-- the switch and port the metric is for.  Since this data is present for all
-- slingshot metrics and is critical for querying we store this information seperatly
-- Key, value pairs are unique since the series join table will reference the id for these
-- This allows for compact storage of metadata
CREATE TABLE IF NOT EXISTS label (
    id SERIAL CHECK (id > 0),
    key TEXT,
    value TEXT,
    PRIMARY KEY (id) INCLUDE (key, value),
    UNIQUE (key, value) INCLUDE (id)
);

-- Track position of lables in the series label array
-- The label array in the series is ordered
-- to allow for efficient group by and lookup
-- The order of the label array is defined for a metric
-- e.g. for metric slingshot_voltage_asic the order for 
-- the lables for every series row related to this metric
-- will be [Index, ParentalIndex, SubIndex, DeviceSpecificationContext, SsstValue]
CREATE TABLE IF NOT EXISTS label_key_position (
    metric_category TEXT, --the category of metric
    metric_name TEXT, --references metric.metric_name NOT metric.id for performance reasons
    key TEXT, --NOT label_key.id for performance reasons.
    pos INT,
    UNIQUE (metric_category, metric_name, key) INCLUDE (pos)
);

-- A table used by the connector for efficient lookups
-- of series ID's based on the given set of labels
-- The index is on the label_key which is the labels
-- sorted by the key and the key concatenated to the value
-- the series_id column is stored in the index itself so that
-- the lookup does not need to go to the table
-- the index is UNIQUE because series are unique sets of labels
CREATE TABLE IF NOT EXISTS series_lookup(
    label_key TEXT NOT NULL,
    series_id INT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_series_lookup_label_key ON series_lookup (label_key) INCLUDE (series_id);

-- Table to track which metrics have been stored
-- mapping them to their table names and other metadata
-- The default intervals are
-- chunk_interval => 1 hour
-- compression_interval => 24 hours
-- retention_period => 30 days
-- The actual policies will be appropriatly scaled for the resolution of the timestamp column based on timestam_scale_factor
CREATE TABLE IF NOT EXISTS metric (
    id SERIAL PRIMARY KEY,
    metric_name text NOT NULL,
    metric_category text NOT NULL,
    metric_type text NOT NULL,
    table_name name NOT NULL,
    timestamp_scale_factor int NOT NULL DEFAULT 1,
    chunk_interval int NOT NULL DEFAULT 3600, -- The timespan contained in each chunk calculated as chunk_interval * timestamp_scale_factor (e.g 3600 * 1000 = 3600000 milliseconds)
    compression_interval int NOT NULL DEFAULT 604800, -- The amount of time after which chunks will be compressed. Calculated as compression_interval * timestamp_scale_factor
    retention_interval int NOT NULL DEFAULT 2592000, -- The amount of time after which chunks will be dropped.  Calculated as retention_period * timestamp_scale_factor
    creation_completed BOOLEAN NOT NULL DEFAULT FALSE, -- Indicates that the series partition for this metric has been attached to the series table
    UNIQUE (metric_name, metric_category) INCLUDE (table_name),
    UNIQUE (table_name)
);

-- Note this function must exist on all data nodes
-- the cm monitoring timescaledb ensure this function 
-- is created on each data node that is added
CREATE OR REPLACE FUNCTION unix_now() returns BIGINT LANGUAGE SQL STABLE as $$ SELECT extract(epoch from now())::BIGINT $$;
CREATE OR REPLACE FUNCTION unix_now_millis() returns BIGINT LANGUAGE SQL STABLE as $$ SELECT (extract(epoch from now()) * 1000)::BIGINT $$;

-- Get a new label array position for a label key. For any metric,
-- we want the positions to be as compact as possible.
-- This uses some pretty heavy locks so use sparingly.
-- locks: label_key_position, data table, series partition (in view creation),
CREATE OR REPLACE FUNCTION get_new_pos_for_key(
        metric_category text, metric_name text, key_name text)
    RETURNS int
AS $func$
DECLARE
    position int;
    next_position int;
    metric_table NAME;
    foo text;
    bar text;
BEGIN
    --use double check locking here
    --fist optimistic check:
    SELECT
        pos
    FROM
        label_key_position lkp
    WHERE
        lkp.metric_category = get_new_pos_for_key.metric_category
        AND lkp.metric_name = get_new_pos_for_key.metric_name
        AND lkp.key = get_new_pos_for_key.key_name
    INTO position;

    IF FOUND THEN
        RETURN position;
    END IF;

    -- get the metric_table and create it if it doesn't exist
    -- label_key_position stores the metric name and category
    -- since the same metric may exist for multiple categories
    -- of metrics.
    SELECT m.table_name
    FROM metric m
    WHERE m.metric_category = get_new_pos_for_key.metric_category
        AND m.metric_name = get_new_pos_for_key.metric_name
    INTO metric_table;

    --lock as for ALTER TABLE because we are in effect changing the schema here
    --also makes sure the next_position below is correct in terms of concurrency
    EXECUTE format('LOCK TABLE %I IN SHARE UPDATE EXCLUSIVE MODE', 'series_' || metric_table);

    --second check after lock
    SELECT
        pos
    FROM
        label_key_position lkp
    WHERE
        lkp.metric_category = get_new_pos_for_key.metric_category
        AND lkp.metric_name = get_new_pos_for_key.metric_name
        AND lkp.key =  get_new_pos_for_key.key_name INTO position;

    IF FOUND THEN
        RETURN position;
    END IF;

    IF key_name = '__name__' THEN
       next_position := 1; -- 1-indexed arrays, __name__ as first element
    ELSE
        -- Get current max pos
        SELECT
            max(pos) + 1
        FROM
            label_key_position lkp
        WHERE
            lkp.metric_category = get_new_pos_for_key.metric_category
            AND lkp.metric_name = get_new_pos_for_key.metric_name 
        INTO next_position;

        IF next_position IS NULL THEN
            next_position := 2; -- element 1 reserved for __name__
        END IF;
    END IF;

    -- Attempt to insert, if it fails raise an exception
    INSERT INTO label_key_position
        VALUES (get_new_pos_for_key.metric_category, get_new_pos_for_key.metric_name, key_name, next_position)
    ON CONFLICT 
        DO NOTHING
    RETURNING
        pos INTO position;

    -- FOUND will be false if no row is affected
    -- If there is a conflict DO NOTHING will result
    -- in no rows being affected and thus this
    -- exception will be raised
    IF NOT FOUND THEN
        RAISE 'Could not find a new position';
    END IF;

    RETURN position;
END
$func$
LANGUAGE PLPGSQL;

-- Get the array position for a label key for a particular metric
-- if the position does not exist create a new position
CREATE OR REPLACE FUNCTION get_or_create_label_key_pos(
        metric_category text, metric_name text, key text)
    RETURNS INT
AS $$
    --only executes the more expensive PLPGSQL function if the label doesn't exist
    SELECT
        pos
    FROM
        label_key_position lkp
    WHERE
        lkp.metric_category = get_or_create_label_key_pos.metric_category 
        AND lkp.metric_name = get_or_create_label_key_pos.metric_name
        AND lkp.key = get_or_create_label_key_pos.key
    UNION ALL
    SELECT
        get_new_pos_for_key(get_or_create_label_key_pos.metric_category, get_or_create_label_key_pos.metric_name, get_or_create_label_key_pos.key)
    LIMIT 1
$$
LANGUAGE SQL VOLATILE;

-- Creates a new label for the key/value pair and returns the ID
--should only be called after a check that that the label doesn't exist
CREATE OR REPLACE FUNCTION get_new_label_id(key_name text, value_name text, OUT id INT)
AS $func$
BEGIN
LOOP
    -- Attempt to insert, if there is a conflict do nothing
    INSERT INTO
        label(key, value)
    VALUES
        (key_name,value_name)
    ON CONFLICT 
        DO NOTHING
    RETURNING 
        label.id
    INTO id;

    EXIT WHEN FOUND;

    -- INSERT failed check if the new id is visible yet
    SELECT
        l.id
    INTO id
    FROM label l
    WHERE
        key = key_name AND
        value = value_name;

    EXIT WHEN FOUND;

    -- loop around and try the insert again
    -- the previous failure could have been
    -- caused by a transaction that itself failed
    -- and needed to rollback so we insert then
    -- insert the label ourselves.
    -- It can also take a bit of time for the transaction
    -- to commit and the new row to be visible to the select
    -- here.
END LOOP;
END
$func$
LANGUAGE PLPGSQL VOLATILE;

-- Get the label ID for the given key/value pair
-- if an ID does not exist it will be created
CREATE OR REPLACE FUNCTION get_or_create_label_id(
        key_name text, value_name text)
    RETURNS INT
AS $$
    --first select to prevent sequence from being used up
    --unnecessarily
    SELECT
        id
    FROM label
    WHERE
        key = key_name AND
        value = value_name
    UNION ALL
    SELECT
        get_new_label_id(key_name, value_name)
    LIMIT 1
$$
LANGUAGE SQL VOLATILE;

-- Create label array
-- This will create all labels that don't exist, along with their positions and return an array representing these labels
-- e.g.
-- key = node_name, value = leader1, key = kernel_version, value = 1.0
-- if key,value exists in label return the id otherwise insert a row and return the new id
-- this id represents the key,value combination, in this case say we have id = 13 and id = 35 for the examples given above
-- A position in the label array is also determined.  Each series for a metric must have the labels appear in the same order
-- If a pos exists for each key return it or create one if it does not
-- In this example node_name gets pos = 0 and kernel_version gets pos = 1
-- The resulting label array is [13,35]
-- This will ultimately be given a serires id say 326 which can then be referenced in the metrics tables
-- by all samples refering to leader1 when its kernel was at version 1.0
-- This provides a compact, high performance way for metric samples (rows in the metrics table) to reference arbitrary metadata
-- that can evolve over time, i.e. metadata can be added or removed without manual intervention to the database
CREATE OR REPLACE FUNCTION get_or_create_label_array(metric_category TEXT, metric_name TEXT, label_keys text[], label_values text[])
RETURNS label_array AS $$
    WITH idx_val AS (
        SELECT
            -- only call the functions to create new key positions
            -- and label ids if they don't exist (for performance reasons)
            -- The functions here will only be triggered by coalesce if the first arg is null
            coalesce(lkp.pos,
              get_or_create_label_key_pos(get_or_create_label_array.metric_category, get_or_create_label_array.metric_name, kv.key)) idx,
            coalesce(l.id,
              get_or_create_label_id(kv.key, kv.value)) val
        -- unnest converts an array into a set of rows, in this case each call to unnest results
        -- in a column in the table expression evaluated by FROM ROWS FROM
        FROM ROWS FROM(unnest(label_keys), unnest(label_values)) AS kv(key, value)
        -- join to the existing data
        LEFT JOIN label l
            ON (l.key = kv.key AND l.value = kv.value)
        LEFT JOIN label_key_position lkp
            ON
            (
                lkp.metric_category = get_or_create_label_array.metric_category AND
                lkp.metric_name = get_or_create_label_array.metric_name AND
                lkp.key = kv.key
            )
        ORDER BY kv.key
    )
    -- Create an array
    -- Generate a series from 1 (Pg is 1 based) to the max pos (idx) for the labels we have
    -- Then LEFT JOIN to the above CTE setting any gaps to 0, ideally there will be few gaps
    -- Since each label must always occupy the same position in the array for every series
    -- for a metric we use 0 as a place holder to indicate no value for this label for this series
    -- example:
    -- g    idx_val(idx,val)
    -- 1    1,7 (label id for leader1)
    -- 2    null
    -- 3    3,32 (label id for kernel version 1.0)
    -- result: [7,0,32]
    SELECT ARRAY(
        SELECT coalesce(idx_val.val, 0)
        FROM
            generate_series(
                    1,
                    (SELECT max(idx) FROM idx_val)
            ) g
        LEFT JOIN idx_val ON (idx_val.idx = g)
    )::label_array -- use custom type, just an int[]
$$
LANGUAGE SQL VOLATILE;
COMMENT ON FUNCTION get_or_create_label_array(text, text, text[], text[])
IS 'converts a metric name, array of keys, and array of values to a label array';

-- Creates a new series for the given metric and set of key/value pairs (labels)
CREATE OR REPLACE FUNCTION create_series(
        metric_id int,
        metric_table_name NAME,
        label_arr label_array,
        OUT series_id BIGINT)
AS $func$
DECLARE
   new_series_id bigint;
BEGIN
  -- grab a new series id
  new_series_id = nextval('series_id');
LOOP
    -- Use the same stratagy as when we insert labels (see get_new_label_id for details)
    EXECUTE format ($$
        INSERT INTO %I(id, metric_id, labels)
        SELECT $1, $2, $3
        ON CONFLICT 
            DO NOTHING
        RETURNING 
            id
    $$, 'series_' || metric_table_name)
    INTO series_id
    USING new_series_id, metric_id, label_arr;

    -- Since we are using dynamic sql with EXECUTE
    -- we use this check instead of FOUND
    EXIT WHEN series_id is not null;

    EXECUTE format($$
        SELECT id
        FROM %I
        WHERE labels = $1
    $$, 'series_' || metric_table_name)
    INTO series_id
    USING label_arr;

    EXIT WHEN series_id is not null;
END LOOP;
END
$func$
LANGUAGE PLPGSQL VOLATILE;

-- reset the delete epoch on a series
CREATE OR REPLACE FUNCTION resurrect_series_ids(metric_table name, series_id bigint)
    RETURNS VOID
AS $func$
BEGIN
    EXECUTE FORMAT($query$
        UPDATE series_%1$I
        SET delete_epoch = NULL
        WHERE id = $1
    $query$, metric_table) using series_id;
END
$func$
LANGUAGE PLPGSQL VOLATILE;

-- Return a table name built from a full_name and a suffix.
-- The full name is truncated so that the suffix could fit in full.
-- name size will always be exactly 62 chars.
CREATE OR REPLACE FUNCTION pg_name_with_suffix(
        full_name text, suffix text)
    RETURNS name
AS $func$
    SELECT (substring(full_name for 62-(char_length(suffix)+1)) || '_' || suffix)::name
$func$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;

-- Return a new unique name from a name and id.
-- This tries to use the full_name in full. But if the
-- full name doesn't fit, generates a new unique name.
-- Note that there cannot be a collision betweeen a user
-- defined name and a name with a suffix because user
-- defined names of length 62 always get a suffix and
-- conversely, all names with a suffix are length 62.

-- We use a max name length of 62 not 63 because table creation creates an
-- array type named `_tablename`. We need to ensure that this name is
-- unique as well, so have to reserve a space for the underscore.

-- In addition this function will sanitize and normalize the full_name
-- It lower cases the full_name and replaces charactesr: . - <space> with _
-- This allows us to maintain the original format of the metric name
-- in the metric table and the __name__ label.
CREATE OR REPLACE FUNCTION pg_name_unique(
        full_name_arg text, suffix text)
    RETURNS name
AS $func$
    SELECT CASE
        WHEN char_length(full_name_arg) < 62 THEN
            lower(replace(replace(replace(full_name_arg, '.', '_'), '-', '_'), ' ', '_'))::name
        ELSE
            pg_name_with_suffix(
                lower(replace(replace(replace(full_name_arg, '.', '_'), '-', '_'), ' ', '_')), suffix
            )
        END
$func$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;

--Add 1% of randomness to the interval so that chunks are not aligned so that chunks are staggered for compression jobs.
CREATE OR REPLACE FUNCTION get_staggered_chunk_interval(chunk_interval BIGINT)
RETURNS BIGINT
AS $func$
    SELECT chunk_interval * (1.0+((random()*0.01)-0.005));
$func$
LANGUAGE SQL VOLATILE;

-- Attach the series partition table for the provided metric to 
-- the parent series table and update creation-completed in metric
-- table to true.  Keeping this separate improves performance as it
-- allows connectors to write to the metric table and series partition
-- immediately. This also avoids a deadlock that can ocurr under high
-- concurrency.
--
-- The deadlock ocurrs as follows
-- The metric table has a unique constraint on metric_name and metric_category
-- This means that any transaction (tx1) that inserts a row with a value that another
-- pending transaction (tx2) is already trying to insert must wait (tx1) on that pending
-- transaction (tx2) to either commit or rollback before it (tx1) can try to commit or rollback.
-- The metric table has an AFTER INSERT trigger that runs to create the metric table, series
-- partition table, and other relevant parts.  In Postgres a trigger runs as part of the
-- original INSERT (or whatever DML) statement's transaction.  This means that the row is
-- not yet visible to other transactions.  Which then means other processes can attempt to
-- insert the same row even though there is a unique constraint; see above.  Which then
-- means that the trigger will also be fired for this row creating the same tables.
-- Another thing to note is that Postgres unlocks locks when a transaction is either
-- committed or rolledback.
-- What happens is 
-- 1. Process 1 attempts to create Metric A
-- 2. Process 1 blocks attempting to lock the series table
-- 3. Process 2 attempts to create Metric A
-- 4. Process 2 acquires lock to the series table
-- 5. Process 2 completes its work and attempts to commit
-- 6. Process 2 must wait for process 1 to commit its transaction since they are both trying to insert the same row in metric
-- 7. Process 1 must wait for process 2 to release the lock on the series table to proceed
-- 8. DEADLOCK
-- 
-- To avoid this we split the creation of the metric table and series partition
-- with attaching the series partition.  This means that there is no
-- lock in the trigger for two separate processes to contend on. And 
-- either one or the other will win the race to insert a particular metric.
-- Then either one or the other will win the race to finalize the metric.
CREATE OR REPLACE PROCEDURE finalize_metric_creation(metric_name_arg TEXT, metric_category_arg TEXT)
AS $proc$
DECLARE
    tbl_name NAME;
    metric_id INT;
    created BOOLEAN;
    pid INT;
BEGIN
    select pg_backend_pid() into pid;
    RAISE NOTICE '% FINALIZE: %', pid, metric_name_arg;
    SELECT table_name, id, creation_completed INTO tbl_name, metric_id, created FROM metric WHERE metric_name = metric_name_arg AND metric_category = metric_category_arg FOR UPDATE;

    IF created THEN
        COMMIT;
        RETURN;
    END IF;

    RAISE NOTICE '% UPDATE METRIC: %', pid, tbl_name;

    UPDATE metric SET creation_completed = TRUE WHERE id = metric_id;

    RAISE NOTICE '% LOCK SERIES: %', pid, tbl_name;
    --we will need this lock for attaching the partition so take it now
    --This may not be strictly necessary but good
    --to enforce lock ordering (parent->child) explicitly. Note:
    --creating a table as a partition takes a stronger lock (access exclusive)
    --so, attaching a partition is better
    -- Note: We don't lock the corresponding row in the metric table for update
    -- as is done in the base version. For our use case we don't have parts
    -- that update this table.
    LOCK TABLE ONLY series IN SHARE UPDATE EXCLUSIVE mode;

    RAISE NOTICE '% ATTACH SERIES PART: %', pid, tbl_name;
    -- Attach the partition
    EXECUTE format($$
        ALTER TABLE series ATTACH PARTITION %1$I FOR VALUES IN (%2$L)
    $$, 'series_' || tbl_name, metric_id);

    COMMIT;

    RAISE NOTICE '% FINALIZED: %', pid, tbl_name;
END;
$proc$ LANGUAGE PLPGSQL;

-- Create a table for a metric
-- This function is called by the make_metric_table_trigger
-- which will ensure that this function is called only once per metric
-- This function will create the table, convert it to a regular
-- or distributed hypertable depending on the availability of data nodes,
-- create the corresponding series table, and setup compression and retention jobs.
--lock-order: data table, labels, series partition.
CREATE OR REPLACE FUNCTION make_metric_table()
    RETURNS trigger
    AS $func$
DECLARE
  label_id INT;
  data_node_cnt INT;
  compress_job_id INT;
  retention_job_id INT;
  pid INT;
BEGIN
    select pg_backend_pid() into pid;
    RAISE NOTICE '% MAKE METRIC TABLE: %', pid, NEW.table_name;
    -- The column arrangment for the metric tables is intentional
    -- For the most common cases (INT8, INT4, FLOAT8, FLOAT4) this arrangment will lead
    -- to the most compact representation of a row.  Currently we only use FLOAT8.
    -- If we put the series_id between ts and val that will cause the
    -- database to pad these columns with 4 extra bytes since they would sit between
    -- an INT8 and a FLOAT8.  The rule of thumb is to place the larger typed columns first
    -- followed by the rest of the columns in descending order. Columns of the same type, or at least
    -- same size, should be placed next to each other.  Doing these things avoids the need 
    -- for the databaes engine to add padding to achieve alignment.
    EXECUTE format('CREATE TABLE %I(ts INT8 NOT NULL, val %s NOT NULL, series_id INT4 NOT NULL) WITH (autovacuum_vacuum_threshold = 50000, autovacuum_analyze_threshold = 50000)',
                    NEW.table_name, NEW.metric_type);
     RAISE NOTICE '% MAKE METRIC INDEX: %', pid, NEW.table_name;
    -- Since we are using the series_id to split the data between data nodes
    -- Timscale will create two indexes by default: One only on the ts column and Two on the series_id and ts columns
    -- In order to reduce impact to write performance and improve read performance we create one index on both the
    -- series_id and ts columns and include the value column in the index itself.  We then disable
    -- creation of default indexes when creating the hypertable.
    EXECUTE format('CREATE INDEX idx_series_id_ts_%s ON %I (series_id, ts DESC) INCLUDE (val)', NEW.id, NEW.table_name);

    SELECT count(*) INTO data_node_cnt from timescaledb_information.data_nodes;

    RAISE NOTICE '% MAKE HYPERTABLE: %', pid, NEW.table_name;
    -- If there are no data nodes we fall back to a regular hypertable
    IF data_node_cnt > 0 THEN
        PERFORM public.create_distributed_hypertable(
            format('public.%I', NEW.table_name),
            'ts',
            'series_id',
            chunk_time_interval=>get_staggered_chunk_interval(NEW.chunk_interval * NEW.timestamp_scale_factor),
            replication_factor => 3, -- replicate the data to two other nodes so that it is stored in 3 places
            create_default_indexes=>false
        );
    ELSE
        PERFORM public.create_hypertable(
            format('public.%I', NEW.table_name),
            'ts',
            chunk_time_interval=>get_staggered_chunk_interval(NEW.chunk_interval * NEW.timestamp_scale_factor),
            create_default_indexes=>false
        );
    END IF;

    RAISE NOTICE '% SETUP JOBS: %', pid, NEW.table_name;

    IF NEW.timestamp_scale_factor = 1 THEN
        EXECUTE format('SELECT set_integer_now_func(''%I'', ''unix_now'')', NEW.table_name);
    ELSIF NEW.timestamp_scale_factor = 1000 THEN
        EXECUTE format('SELECT set_integer_now_func(''%I'', ''unix_now_millis'')', NEW.table_name);
    ELSE
        RAISE EXCEPTION 'Invalid UNIX timestamp scale factor: %.', NEW.timestamp_scale_factor
            USING HINT = 'Supported scale factors: 1 (one second resolution) or 1000 (one millisecond resolution).';
    END IF;

    -- Setup compression, by default data older than 1 day will be compressed
    -- Timescale supposedly runs compression and retention jobs immediately upon their creation.  
    -- This is not quite true there is actually a 1 minute polling interval where the job periodically checks for jobs to run.  
    -- This can lead to data beginning to be inserted before the job runs. Which can cause data to
    -- be immediatly deleted or compressed which can also degrade performance.
    -- In addition when creating many metrics concurrently we don't want to be triggering
    -- a bunch of jobs that won't really be doing anything all at once.
    -- Finally we stagger that start times of these jobs to prevent a storm 
    -- of jobs all starting at once.
    EXECUTE format('ALTER TABLE %I SET (timescaledb.compress, timescaledb.compress_segmentby =''series_id'')', NEW.table_name);
    EXECUTE format('SELECT add_compression_policy(''%I'', %s)', NEW.table_name, NEW.compression_interval * NEW.timestamp_scale_factor::BIGINT) INTO compress_job_id;
    PERFORM alter_job(compress_job_id, next_start => now() + (INTERVAL '1' day) * (1.0+((random()*0.01)-0.005)));

    EXECUTE format('SELECT add_retention_policy(''%I'', %s)', NEW.table_name, NEW.retention_interval * NEW.timestamp_scale_factor::BIGINT) INTO retention_job_id;
    PERFORM alter_job(retention_job_id, next_start => now() + (INTERVAL '1' day) * (1.0+((random()*0.01)-0.005)));

    RAISE NOTICE '% CREATE LABEL: %', pid, NEW.table_name;
    SELECT get_or_create_label_id('__name__', NEW.metric_name)
    INTO STRICT label_id;

    RAISE NOTICE '% CREATE SERIES PART: %', pid, NEW.table_name;
    --note that because labels[1] is unique across partitions and UNIQUE(labels) inside partition, labels are guaranteed globally unique
    EXECUTE format($$
        CREATE TABLE %1$I (
            id INT NOT NULL,
            metric_id INT NOT NULL,
            labels label_array NOT NULL,
            delete_epoch BIGINT NULL DEFAULT NULL,
            CHECK(labels[1] = %2$L AND labels[1] IS NOT NULL),
            CHECK(metric_id = %3$L),
            CONSTRAINT series_labels_id_%3$s UNIQUE(labels) INCLUDE (id),
            CONSTRAINT series_pkey_%3$s PRIMARY KEY(id)
        ) WITH (autovacuum_vacuum_threshold = 100, autovacuum_analyze_threshold = 100)
    $$, 'series_' || NEW.table_name, label_id, NEW.id);


    RAISE NOTICE '% MADE: %', pid, NEW.table_name;
   RETURN NEW;
END
$func$
LANGUAGE PLPGSQL VOLATILE;


-- Attempt to create a metric table, if the table already exists
-- return the its id and name.  Concurrency is handled by 
-- inserting into the metric table, which fires make_metric_table,
-- which calls make_metric_table, which actually makes the table.
-- Any competing insert will fail with a conflict and retrieve the
-- id and table name once it is available
-- The scale factor is used to scale: chunk_interval, compression_interval, retention_interval
-- which will properly scale these to the resolution of the timestamp column (ts)
-- locks: metric, make_metric_table[data table, labels, series partition]
CREATE OR REPLACE FUNCTION create_metric_table(
        metric_name_arg text, metric_category_arg text, metric_type_arg text, scale_factor int, chunk_interval_arg int, compression_interval_arg int, retention_interval_arg int, OUT id int, OUT table_name name)
AS $func$
DECLARE
  new_id int;
BEGIN
new_id = nextval(pg_get_serial_sequence('metric','id'))::int;
LOOP
    INSERT INTO metric (id, metric_name, metric_category, metric_type, table_name, timestamp_scale_factor, chunk_interval, compression_interval, retention_interval)
        SELECT  new_id,
                metric_name_arg,
                metric_category_arg,
                metric_type_arg,
                pg_name_unique(metric_category_arg || '_' || metric_name_arg, new_id::text),
                scale_factor,
                chunk_interval_arg,
                compression_interval_arg,
                retention_interval_arg
    ON CONFLICT 
        DO NOTHING
    RETURNING 
        metric.id, metric.table_name
    INTO id, table_name;
    -- under high concurrency the insert may not return anything, so try a select and loop
    -- https://stackoverflow.com/a/15950324
    EXIT WHEN FOUND;

    SELECT m.id, m.table_name
    INTO id, table_name
    FROM metric m
    WHERE metric_name = metric_name_arg AND metric_category = metric_category_arg;

    EXIT WHEN FOUND;
END LOOP;
END
$func$
LANGUAGE PLPGSQL VOLATILE;

-- Create the trigger
DROP TRIGGER IF EXISTS make_metric_table_trigger ON metric CASCADE;
CREATE TRIGGER make_metric_table_trigger
    AFTER INSERT ON metric
    FOR EACH ROW
    EXECUTE PROCEDURE make_metric_table();

-- Create Series Entry
-- Takes in keys and values and will create the labels if they don't exist 
-- it will then create the series if it does not exist
CREATE OR REPLACE FUNCTION get_or_create_series_id_for_kv_array(metric_category_arg TEXT, metric_name_arg TEXT, label_keys text[], label_values text[], OUT table_name NAME, OUT series_id BIGINT)
AS $func$
DECLARE
  metric_id INT;
BEGIN
   -- In our version we require the table to exists, this is because we allow the
   -- timestamp column (ts) in the metric tables to have different resolution from
   -- metric to metric and we store it as a UNIX timestamp.  This means we can't use
   -- an INTERVAL expression to define the chunk interval, we need to use an integer
   -- which will be different for msec and sec resolutions to achieve the same chunk interval
   -- This would rquire needing to pass more parameters into this function which
   -- is already complex
   SELECT m.id, m.table_name::name
   FROM metric m
   WHERE m.metric_name = metric_name_arg AND m.metric_category = metric_category_arg
   INTO metric_id, table_name;

   -- the data table could be locked during label key creation
   -- and must be locked before the series parent according to lock ordering
   EXECUTE format($query$
        LOCK TABLE ONLY %1$I IN ACCESS SHARE MODE
    $query$, table_name);

   EXECUTE format($query$
    WITH cte AS (
        SELECT get_or_create_label_array($1, $2, $3, $4) -- create the label array
    ), existing AS (
        SELECT
            id,
            -- We will include delete_epoch, but will not use it initially
            -- basically if a series row has been marked as available for
            -- deletion but it ends up matching the where clause (lables = larray)
            -- we "undelete" it since we will be putting it back to use here
            CASE WHEN delete_epoch IS NOT NULL THEN
                resurrect_series_ids(%1$L, id)
            END
        FROM %3$I as series -- The data_series schema contains the partitions of the series table for each metric
        WHERE labels = (SELECT * FROM cte) -- This should match when labels and the new label array exactly match by position
    )
    SELECT id FROM existing -- get all existing records
    UNION ALL
    SELECT create_series(%2$L, %1$L, (SELECT * FROM cte)) -- create the series if it doesn't exist, note the query will result in our newly created label array
    LIMIT 1 -- limit will break execution immediatly when it is reached, so if the top clause of union all returns a record the bottom create clause will not execute
   $query$, table_name, metric_id, 'series_' || table_name) -- formatting params
   USING metric_category_arg, metric_name_arg, ARRAY['__name__'] || ARRAY['__category__'] || label_keys, ARRAY[metric_name_arg] || ARRAY[metric_category_arg] || label_values -- pass in the metric, our label names and values
   INTO series_id; -- get the series_id as the result

    -- Insert into the lookup table
    INSERT INTO series_lookup (label_key, series_id)
    SELECT
        string_agg(ordered_labels.key || ordered_labels.value, ',') str_key,
        series_id
    FROM (
        SELECT kv.key, kv.value
        FROM ROWS FROM(unnest(ARRAY['__name__'] || ARRAY['__category__'] || label_keys), unnest(ARRAY[metric_name_arg] || ARRAY[metric_category_arg] || label_values)) AS kv(key, value)
        ORDER BY kv.key ASC) ordered_labels
    ON CONFLICT DO NOTHING;

   RETURN;
END
$func$
LANGUAGE PLPGSQL VOLATILE; -- The function value can change even within a single table scan, so no optimizations can be performed. This is the default, but we are being explicit.

-- Bulk insert metric data into the metric table
-- The data is packed as arrays for each column
-- which is then bulk inserted via a single insert
-- Reasoning below taken from: https://github.com/timescale/promscale/blob/d07e837862717bfa858131617d71650a55893f6f/pkg/pgmodel/ingestor/copier.go#L223
-- flatten the various series into arrays.
-- there are four main bottlenecks for insertion:
--   1. The round trip time.
--   2. The number of requests sent.
--   3. The number of individual INSERT statements.
--   4. The amount of data sent.
-- While the first two of these can be handled by batching, for the latter
-- two we need to actually reduce the work done. It turns out that simply
-- collecting all the data into a postgres array and performing a single
-- INSERT using that overcomes most of the performance issues for sending
-- multiple data, and brings INSERT nearly on par with CopyFrom. In the
-- future we may wish to send compressed data instead.
CREATE OR REPLACE FUNCTION insert_metric_row(
    metric_table name,
    time_array bigint[],
    value_array float8[],
    series_array int[]
) RETURNS BIGINT 
LANGUAGE PLPGSQL
AS
$$
DECLARE
  num_rows BIGINT;
BEGIN
    EXECUTE FORMAT(
     'INSERT INTO  public.%1$I (ts, val, series_id)
          SELECT * FROM unnest($1, $2, $3) a(t,v,s) ORDER BY s,t',
        metric_table
    ) USING time_array, value_array, series_array;
    GET DIAGNOSTICS num_rows = ROW_COUNT;
    RETURN num_rows;
END;
$$;

CREATE OR REPLACE FUNCTION insert_str_metric_row(
    metric_table name,
    time_array bigint[],
    value_array text[],
    series_array int[]
) RETURNS BIGINT 
LANGUAGE PLPGSQL
AS
$$
DECLARE
  num_rows BIGINT;
BEGIN
    EXECUTE FORMAT(
     'INSERT INTO  public.%1$I (ts, val, series_id)
          SELECT * FROM unnest($1, $2, $3) a(t,v,s) ORDER BY s,t',
        metric_table
    ) USING time_array, value_array, series_array;
    GET DIAGNOSTICS num_rows = ROW_COUNT;
    RETURN num_rows;
END;
$$;

-- Attaches the data nodes to all distributed hypertables
-- Newly added data nodes will not be used until they
-- are attached to distributed hypertables.
-- This function will ensure each data node is attached
-- to each distributed hypertable listed in the metric
-- table.  NOTE: data is not rebalanced, the new data 
-- nodes are simply available to recieve new data.
CREATE OR REPLACE FUNCTION attach_data_nodes_all(
    node_names text[]
) RETURNS TABLE(hypertable_id integer, node_hypertable_id integer, node_name name, table_name name) 
LANGUAGE PLPGSQL
AS
$$
BEGIN
    RETURN QUERY
    SELECT 
        res.hypertable_id, 
        res.node_hypertable_id,
        res.node_name, 
        h.hypertable_name table_name 
    FROM unnest((node_names)::text[]) nn 
    CROSS JOIN timescaledb_information.hypertables h
    CROSS JOIN LATERAL attach_data_node(nn::name, h.hypertable_name::regclass) res
    WHERE h.is_distributed = true;
END;
$$;

-- Adds the provided nodes as data nodes
-- host_names is the host name of the node to add
-- node_names is the name Timescale should assign
-- to the node
-- NOTE: The order matters, host_names[1] will use node_names[1]
-- as the node name.
CREATE OR REPLACE FUNCTION add_data_nodes(
    node_names text[],
    host_names text[],
    node_ports integer[]
) RETURNS TABLE(node_name name, host text, port integer, database name, node_created boolean, database_created boolean, extension_created boolean)
LANGUAGE PLPGSQL
AS
$$
BEGIN
    RETURN QUERY
    SELECT
       res.* 
    FROM unnest((node_names)::text[], (host_names)::text[], (node_ports)::integer[]) as args(nn, hn, p)
    CROSS JOIN LATERAL add_data_node(nn::text, hn::text, port => p::integer) res;
END;
$$;

-- Adds the provided nodes as data nodes
-- and attaches the new newly added data nodes
-- to all distributed hypertables
-- host_names is the host name of the node to add
-- node_names is the name Timescale should assign
-- to the node
-- NOTE: The order matters, host_names[1] will use node_names[1]
-- as the node name.
CREATE OR REPLACE FUNCTION bring_up_data_nodes(
    node_names text[],
    host_names text[],
    node_ports integer[]
) RETURNS BOOLEAN
LANGUAGE PLPGSQL
AS
$$
DECLARE
    success BOOLEAN;
    attachments INTEGER := -1;
    expected_attachments INTEGER := -2;
BEGIN
    SELECT (node_created AND database_created AND extension_created) INTO success FROM add_data_nodes(node_names, host_names, node_ports);

    IF success THEN
        SELECT count(*) INTO attachments FROM attach_data_nodes_all(node_names);
        SELECT (array_length(node_names, 1) * count(*)) INTO expected_attachments FROM timescaledb_information.hypertables WHERE is_distributed = true;
    END IF;

    RETURN (attachments = expected_attachments AND success);
END;
$$;

CREATE OR REPLACE FUNCTION get_label_pos(_metric_category TEXT, _metric_name TEXT, _label TEXT)
RETURNS BIGINT
AS
$$
    SELECT pos 
    FROM label_key_position lkp 
    WHERE 
        metric_category = _metric_category
        AND metric_name = _metric_name
        AND key = _label;
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION get_label_id_from_series_id(_metric_category TEXT, _metric_name TEXT, _label TEXT, _series_id INT)
RETURNS BIGINT
AS 
$func$
DECLARE
    label_id INT;
BEGIN
    EXECUTE format($$
        SELECT 
            s.labels[(SELECT get_label_pos(%2$L, %3$L, %4$L))] label_id
        FROM %1$I s 
        WHERE id = %5$s
    $$, 'series_' || _metric_category || '_' || _metric_name, _metric_category, _metric_name, _label, _series_id)
    INTO label_id; 

    RETURN label_id;
END;
$func$
LANGUAGE PLPGSQL STABLE;

CREATE OR REPLACE FUNCTION get_label_id_from_series(_metric_category TEXT, _metric_name TEXT, _label TEXT, _label_ids label_array)
RETURNS BIGINT
AS 
$func$
DECLARE
    label_id INT;
BEGIN
    SELECT _label_ids[(SELECT get_label_pos(_metric_category, _metric_name, _label))] label_id
    INTO label_id; 

    RETURN label_id;
END;
$func$
LANGUAGE PLPGSQL STABLE;

CREATE OR REPLACE FUNCTION get_label_from_series(_metric_category TEXT, _metric_name TEXT, _label TEXT, _series_id INT)
RETURNS TEXT
AS
$$
    SELECT 
        l.value 
    FROM label l
    WHERE l.id = (SELECT get_label_id_from_series_id(_metric_category, _metric_name, _label, _series_id)) ;
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION get_label_from_series(_metric_category TEXT, _metric_name TEXT, _label TEXT, _label_ids label_array)
RETURNS TEXT
AS
$$
    SELECT 
        l.value 
    FROM label l
    WHERE l.id = _label_ids[(SELECT get_label_pos(_metric_category, _metric_name, _label))];
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION get_series_for_labels(metric_category TEXT, metric_name TEXT, labels TEXT[], label_vals TEXT[][])
RETURNS TABLE(id INT, lbls label_array)
AS $func$
DECLARE
    i INTEGER;
    filters TEXT = '';
    built_query TEXT;
    label_filter TEXT = '';
BEGIN
    FOR i IN 1 .. array_upper(labels, 1)
    LOOP
        label_filter := (SELECT string_agg('''' || lid || '''', ',') FROM unnest(label_vals[i:i]) as x(lid));
        filters := filters || format('AND s.labels && (SELECT COALESCE(array_agg(l.id), array[]::int[]) FROM label l WHERE l.key = ''%s'' AND l.value IN (%s))', labels[i], label_filter);
    END LOOP;

    built_query := format('
        SELECT s.id, s.labels
        FROM %s s
        WHERE 
            1=1
            %s
    ', 'series_' || metric_category || '_' || metric_name, filters);

    RETURN QUERY
    EXECUTE built_query;
END;
$func$
LANGUAGE PLPGSQL STABLE;

CREATE OR REPLACE FUNCTION get_metric_data(metric_category TEXT, metric_name TEXT, start_ts BIGINT, end_ts BIGINT, labels TEXT[], label_vals TEXT[][])
RETURNS TABLE(ts BIGINT, val FLOAT8, lbls label_array)
AS $func$
BEGIN
    RETURN QUERY
    EXECUTE format($$
        SELECT
            m.ts,
            m.val,
            (SELECT s.lbls FROM get_series_for_labels(%2$L, %3$L, $1, $2) s WHERE id = m.series_id) label_ids
        FROM %1$I m
        WHERE
            ARRAY[m.series_id] && (SELECT coalesce(array_agg(id), array[]::integer[]) FROM get_series_for_labels(%2$L, %3$L, $1, $2) x)
            AND m.ts BETWEEN %4$s AND %5$s
    $$, metric_category || '_' || metric_name, metric_category, metric_name, start_ts, end_ts)
    USING labels, label_vals;
END;
$func$
LANGUAGE PLPGSQL STABLE;

CREATE OR REPLACE FUNCTION get_agg_metric_data(_metric_category TEXT, _metric_name TEXT, _start_ts BIGINT, _end_ts BIGINT, _labels TEXT[], _label_vals TEXT[][], _bucket_interval BIGINT, _agg_fun TEXT, _group_by_labels TEXT[])
RETURNS TABLE(ts BIGINT, val FLOAT8, lbls label_array)
AS $func$
DECLARE
    i INTEGER;
    select_label_ids TEXT = '';
    groupby_labels TEXT = '';
BEGIN
    FOR i IN 1 ..array_upper(_group_by_labels,1)
    LOOP
        select_label_ids := select_label_ids || format($$ get_label_id_from_series_id(%1$L, %2$L, %3$L, m.series_id) %4$s,$$, _metric_category, _metric_name, _group_by_labels[i], _group_by_labels[i]);
        groupby_labels := groupby_labels || format('%s,', _group_by_labels[i]);
    END LOOP;

    select_label_ids := RTRIM(select_label_ids, ',');
    groupby_labels := RTRIM(groupby_labels, ',');

    RETURN QUERY
    EXECUTE format($$
        SELECT
            ts_b, 
            %7$s(val) OVER (PARTITION BY ts_b, %9$s) val_a,
            label_ids
        FROM
        (
            SELECT
                time_bucket(%6$s,m.ts) ts_b,
                m.val,
                (SELECT s.lbls FROM get_series_for_labels(%2$L, %3$L, $1, $2) s WHERE id = m.series_id) label_ids, 
                %8$s
            FROM %1$I m
            WHERE
                ARRAY[m.series_id] && (SELECT coalesce(array_agg(id), array[]::integer[]) FROM get_series_for_labels(%2$L, %3$L, $1, $2) x)
                AND m.ts BETWEEN %4$s AND %5$s
        ) a
    $$, _metric_category || '_' || _metric_name, _metric_category, _metric_name, _start_ts, _end_ts, _bucket_interval, _agg_fun, select_label_ids, array_to_string(_group_by_labels, ','))
    USING _labels, _label_vals;
END;
$func$
LANGUAGE PLPGSQL STABLE;

CREATE OR REPLACE FUNCTION get_chunk_repl_restore_plan() 
RETURNS TABLE(chunk_full_name text, src_node_name name, dst_node_name name)
LANGUAGE PLPGSQL
AS
$$
BEGIN
    RETURN QUERY
    WITH chunk_repl_status AS (
        SELECT
            a.ht_full_name,
            a.chunk_full_name,
            a.node_name,
            a.replication_factor,
            COUNT(*) OVER (PARTITION BY a.chunk_full_name) cnt
        FROM (
            SELECT 
                h.hypertable_schema || '.' || h.hypertable_name ht_full_name,
                c.chunk_schema || '.' || c.chunk_name chunk_full_name, 
                unnest(c.data_nodes) node_name,
                h.replication_factor
            FROM timescaledb_information.chunks c 
            JOIN timescaledb_information.hypertables h 
                ON 
                    c.hypertable_schema = h.hypertable_schema
                    AND c.hypertable_name = h.hypertable_name
        ) a
    )
    SELECT DISTINCT ON (chunk_src_dest.chunk_full_name, chunk_src_dest.dst_node_name)
    chunk_src_dest.chunk_full_name,
    chunk_src_dest.src_node_name,
    chunk_src_dest.dst_node_name
    FROM (
        SELECT
            cdn.chunk_full_name,
            cdn.node_name AS src_node_name,
            adn.node_name AS dst_node_name,
            cdn.replication_factor,
            dense_rank() OVER (PARTITION BY cdn.chunk_full_name ORDER BY adn.node_name) + cdn.cnt r
        FROM chunk_repl_status cdn
        JOIN (
            SELECT 
                h.hypertable_schema || '.' || h.hypertable_name ht_full_name,
                unnest(h.data_nodes) node_name 
            FROM timescaledb_information.hypertables h
        ) adn 
        ON 
            cdn.ht_full_name = adn.ht_full_name
            AND cdn.node_name <> adn.node_name 
            AND adn.node_name NOT IN (
                SELECT 
                    node_name 
                FROM chunk_repl_status x 
                WHERE x.chunk_full_name = cdn.chunk_full_name
            )
    ) chunk_src_dest
    WHERE
        chunk_src_dest.r <= chunk_src_dest.replication_factor
    ORDER BY chunk_src_dest.chunk_full_name, chunk_src_dest.dst_node_name, random();
END;
$$;

-- Timescale tracks remote transactions on the access node in _timescaledb_catalog.remote_txn
-- Transactions can endup stuck for a number of different reasons and must be periodically
-- cleaned up.  Timescale suggests the following maintance job which will run the 
-- a function to heal these transactions.  If this job is not run the remote_txn
-- table will grow indefinetly.
-- https://docs.timescale.com/timescaledb/latest/how-to-guides/multinode-timescaledb/multinode-maintenance/#maintaining-distributed-transactions
CREATE OR REPLACE PROCEDURE data_node_maintenance(job_id int, config jsonb)
LANGUAGE SQL AS
$$
    SELECT _timescaledb_internal.remote_txn_heal_data_node(fs.oid)
    FROM pg_foreign_server fs, pg_foreign_data_wrapper fdw
    WHERE fs.srvfdw = fdw.oid
    AND fdw.fdwname = 'timescaledb_fdw';
$$;

SELECT add_job('data_node_maintenance', '5m');

-- Postgres' auto-vacuum feature does not work with distributed hypertables
-- We create a maintenance job to perodically analyze distributed hypertables
-- to keep their statistics up to date.
CREATE OR REPLACE PROCEDURE distributed_hypertables_analyze(job_id int, config jsonb)
LANGUAGE plpgsql AS
$$
DECLARE r record;
BEGIN
FOR r IN SELECT hypertable_schema, hypertable_name
              FROM timescaledb_information.hypertables
              WHERE is_distributed ORDER BY 1, 2
LOOP
EXECUTE format('ANALYZE %I.%I', r.hypertable_schema, r.hypertable_name);
END LOOP;
END
$$;

SELECT add_job('distributed_hypertables_analyze', '12h');


-- slingshot stuff
-- Use natural order since the data is not high volume
CREATE TABLE slingshot_switch_state (
    ts INT8 NOT NULL,
    switch TEXT NOT NULL,
    switch_group INT4 NOT NULL,
    switch_num INT4 NOT NULL,
    switch_type TEXT NOT NULL,
    edge_links INT4 NOT NULL,
    local_links INT4 NOT NULL,
    global_links INT4 NOT NULL,
    unused INT4 NOT NULL,
    uptime INT8 NOT NULL,
    temperature FLOAT8 NOT NULL,
    software TEXT NOT NULL,
    serial_num TEXT NOT NULL,
    error_msg TEXT NULL,
    status_code INT4 NOT NULL
);

SELECT create_hypertable('slingshot_switch_state', 'ts', chunk_time_interval => 604800);
SELECT set_integer_now_func('slingshot_switch_state', 'unix_now');
CREATE INDEX idx_slingshot_switch_state_group_switch_num_ts ON slingshot_switch_state (switch_group, switch_num, ts DESC);
CREATE INDEX idx_slingshot_switch_state_group_switch_ts ON slingshot_switch_state (switch_group, switch, ts DESC);

CREATE TABLE slingshot_link_state (
    ts INT8 NOT NULL,
    switch TEXT NOT NULL,
    switch_group INT4 NOT NULL,
    switch_num INT4 NOT NULL,
    port_num INT4 NOT NULL,
    jack TEXT NOT NULL,
    neighbor TEXT NOT NULL,
    port_type TEXT NOT NULL,
    port_state TEXT NOT NULL,
    port_up INT4 NOT NULL,
    port_down INT4 NOT NULL,
    port_adown INT4 NOT NULL,
    port_delta_up INT4 NOT NULL,
    link_uptime INT8 NOT NULL,
    media TEXT NOT NULL,
    headshell TEXT NOT NULL,
    configured_state TEXT NOT NULL,
    configured_conf TEXT NULL,
    speed TEXT NOT NULL,
    pause TEXT NULL,
    programmed TEXT NOT NULL,
    llr TEXT NULL,
    pcs TEXT NULL,
    lldp_frames INT8 NOT NULL,
    status_code INT4 NOT NULL
);

SELECT create_hypertable('slingshot_link_state', 'ts', chunk_time_interval => 604800);
SELECT set_integer_now_func('slingshot_link_state', 'unix_now');
CREATE INDEX idx_slingshot_link_state_group_switch_num_port_num_ts ON slingshot_link_state (switch_group, switch_num, port_num, ts DESC);
CREATE INDEX idx_slingshot_link_state_group_switch_port_num_ts ON slingshot_link_state (switch_group, switch, port_num, ts DESC);

CREATE TABLE slingshot_switch_state_live (
    ts INT8 NOT NULL,
    switch TEXT NOT NULL,
    switch_group INT4 NOT NULL,
    switch_num INT4 NOT NULL,
    port_num INT4 NOT NULL,
    port_type TEXT NOT NULL,
    port_state TEXT NOT NULL,
    switch_status_code INT4 NOT NULL,
    port_status_code TEXT NOT NULL
);

SELECT create_hypertable('slingshot_switch_state_live', 'ts', chunk_time_interval => 604800);
SELECT set_integer_now_func('slingshot_switch_state_live', 'unix_now');
CREATE INDEX idx_slingshot_switch_state_live_group_switch_num_port_num_ts ON slingshot_switch_state_live (switch_group, switch_num, port_num, ts DESC);
CREATE INDEX idx_slingshot_switch_state_live_group_switch_port_num_ts ON slingshot_switch_state_live (switch_group, switch, port_num, ts DESC);

CREATE TABLE slingshot_fabric_manager_state (
    ts INT8 NOT NULL,
    fabric_manager TEXT NOT NULL,
    edge_online INT4 NOT NULL,
    edge_offline INT4 NOT NULL,
    edge_total INT4 NOT NULL,
    fabric_online INT4 NOT NULL,
    fabric_offline INT4 NOT NULL,
    fabric_total INT4 NOT NULL,
    unsync_switch_count INT4 NOT NULL,
    total_switches INT4 NOT NULL
);

SELECT create_hypertable('slingshot_fabric_manager_state', 'ts', chunk_time_interval => 604800);
SELECT set_integer_now_func('slingshot_fabric_manager_state', 'unix_now');
CREATE INDEX idx_slingshot_fabric_manager_state_fabric_manager_ts ON slingshot_fabric_manager_state (fabric_manager, ts DESC);

