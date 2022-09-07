#! /bin/bash

function process_data() {
  psql -h localhost -p 9433 -U postgres -d monitoringdb -f commands_pid_107.sql &
  pids[0]=$!
  psql -h localhost -p 9433 -U postgres -d monitoringdb -f commands_pid_108.sql &
  pids[1]=$!
  psql -h localhost -p 9433 -U postgres -d monitoringdb -f commands_pid_109.sql &
  pids[2]=$!
  psql -h localhost -p 9433 -U postgres -d monitoringdb -f commands_pid_110.sql &
  pids[3]=$!
  psql -h localhost -p 9433 -U postgres -d monitoringdb -f commands_pid_111.sql &
  pids[4]=$!
  psql -h localhost -p 9433 -U postgres -d monitoringdb -f commands_pid_112.sql &
  pids[5]=$!
  psql -h localhost -p 9433 -U postgres -d monitoringdb -f commands_pid_113.sql &
  pids[6]=$!
  psql -h localhost -p 9433 -U postgres -d monitoringdb -f commands_pid_114.sql &
  pids[7]=$!

  for pid in ${pids[*]}; do
      wait $pid
  done
}

function teardown() {
  docker-compose down -v
  echo "done"
  exit 2
}

trap teardown SIGINT

echo "launch test docker environment"
docker-compose up -d
echo "wait for Postgres to be fully up"
sleep 10 
echo "start load test"
process_data
read -p "DONE, press any key to tear down test docker environment"
teardown
