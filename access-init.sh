#!/bin/sh
set -e

# Helper script that will be run as part of the Postgres docker container's init procedure
# Modifies the postgresql.conf file to enable multi-node TimeScaleDB
# It MUST wait for the data node containers to be up and available as the next files
# that the init procedure will run are the 888 and 999 sql files which will
# setup the database and add these docker containers as data nodes.

sed -ri "s/^#?(enable_partitionwise_aggregate)[[:space:]]*=.*/\1 = on/;s/^#?(wal_level)[[:space:]]*=.*/\1 = logical/;s/^#?(jit)[[:space:]]*=.*/\1 = off/;s/^#?(log_parameter_max_length_on_error)[[:space:]]*=.*/\1 = -1/;s/^#?(log_parameter_max_length)[[:space:]]*=.*/\1 = -1/;s/^#?(log_statement)[[:space:]]*=.*/\1 = all/;s/^#?(log_error_verbosity)[[:space:]]*=.*/\1 = VERBOSE/;s/^#?(log_min_messages)[[:space:]]*=.*/\1 = DEBUG1/" /var/lib/postgresql/data/postgresql.conf

echo "Waiting for data nodes..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h tsdb-data1 -U "$POSTGRES_USER" -c '\q'; do
    sleep 5s
done
until PGPASSWORD=$POSTGRES_PASSWORD psql -h tsdb-data2 -U "$POSTGRES_USER" -c '\q'; do
    sleep 5s
done
until PGPASSWORD=$POSTGRES_PASSWORD psql -h tsdb-data3 -U "$POSTGRES_USER" -c '\q'; do
    sleep 5s
done
until PGPASSWORD=$POSTGRES_PASSWORD psql -h tsdb-data4 -U "$POSTGRES_USER" -c '\q'; do
    sleep 5s
done
