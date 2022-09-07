# Reproduce "insert is not on a table" Error in Timescale
Provides scripts which will reproduce the error "insert is not on a table" error in Timescale.  The error appears to be a race condition as this script can only trigger the error in around 75% of attempts.  In addition, from run to run, the error will be hit different numbers of times, different "commands" scripts will trigger the error, and the error will be occur on different tables.

## Running the Test
```
./run-test.sh
```
While the test is running you can run the below command to check the access node logs to determine if the error has been encountered
```
docker-compose logs tsdb-access | grep "insert is not on a table"
```

## Background
Our data pipeline has various samplers collecting telemetry and sending that telemetry to Kafka.  We then use Kafka Connect to process the data from Kafka into Timescale.  We use a custom connector to allow us to write to our particular Timescale database which uses a table per metric instead of a table per topic as the standard Kafka Connect JDBC connector expects.  We typically have hundreds of distributed hypertables with hour chunks, many with billions of rows, and over a hundred Kafka Connect tasks writing to the database concurrently with a sample rate of 1 Hz for many metrics; the distributed hypertables are configured with 3-way replication.  I typically see this error encountered a few times in a 24 hour period when running on a lab system.  I can consistently reproduce the error by running the whole pipeline in docker on my laptop.  The error also appears to be due to concurrency when running the pipeline locally I need to be running at least 8 Kafka Connect tasks in order to reproduce the error.  Finally the error is timing dependent as it will be hit by different Kafka Connect tasks at different times on different tables each run.

## How the Test Works
The test works by creating a Timescale cluster using Docker Compose with 1 access node and 4 data nodes; the schema can be found in the monitoringdb-setup.sql file.  It then launches 8 subprocesses each of which execute one of the commands_pid_xxx.sql files and waiting for them to complete.  Once completed, or if the script is sent SIGINT (e.g. with ctrl-c), it will teardown the docker environment.  Each of the SQL files is a capture of all the SQL commands that were executed by a Kafka Connect task when this error was encountered during a test of our full data pipeline.  By launching 8 subprocesses this simulates the 8 Kafka Connect tasks concurrently writing to the database.  Each subprocess will execute all the same SQL commands that the Kafka Connect task did when the error was encountered.  The error will manifest in approximately 75% of attempts. The error typically occurs with in the first 5 minutes of a run.  This test was run on an Intel based Macbook Pro running macOS Monterey.