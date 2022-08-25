#!/bin/sh
set -e

# Helper script that will be run as part of the Postgres docker container's init procedure
# Modifies the postgresql.conf file to enable multi-node TimeScaleDB

sed -ri "s/^#?(max_prepared_transactions)[[:space:]]*=.*/\1 = 150/;s/^#?(wal_level)[[:space:]]*=.*/\1 = logical/;s/^#?(log_parameter_max_length_on_error)[[:space:]]*=.*/\1 = -1/;s/^#?(log_error_verbosity)[[:space:]]*=.*/\1 = VERBOSE/;s/^#?(log_min_messages)[[:space:]]*=.*/\1 = DEBUG1/" /var/lib/postgresql/data/postgresql.conf