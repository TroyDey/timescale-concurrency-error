-- Connect access node to data nodes
CREATE EXTENSION IF NOT EXISTS timescaledb;
SELECT add_data_node('dn1', host => 'tsdb-data1');
SELECT add_data_node('dn2', host => 'tsdb-data2');
SELECT add_data_node('dn3', host => 'tsdb-data3');
SELECT add_data_node('dn4', host => 'tsdb-data4');

CALL distributed_exec($ee$
DO $DO$
BEGIN
    CREATE OR REPLACE FUNCTION unix_now() returns BIGINT LANGUAGE SQL STABLE as $$ SELECT extract(epoch from now())::BIGINT $$;
END
$DO$;
$ee$);

CALL distributed_exec($ee$
DO $DO$
BEGIN
    CREATE OR REPLACE FUNCTION unix_now_millis() returns BIGINT LANGUAGE SQL STABLE as $$ SELECT (extract(epoch from now()) * 1000)::BIGINT $$;
END
$DO$;
$ee$);
