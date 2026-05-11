#!/bin/bash

set -ex

facd > facd.logs &
pid=$!

# this function should be used to ensure that facd is in a "stable" state
# where all jobs have finished
function facd_wait() {
  TIMEOUT=20
  for i in $(seq 1 $TIMEOUT); do
    response=$(curl -s http://localhost:8000/monitor_jobs)
    queued=$(echo "$response" | jq '.queued | length')
    running=$(echo "$response" | jq '.running | length')
    if [ "$queued" -eq 0 ] && [ "$running" -eq 0 ]; then
      exit 0
    fi
    echo "facd building i=$i"
    sleep 1
  done
  echo "facd_wait() exceeded TIMEOUT=$TIMEOUT"
  exit 1
}

facd_wait
curl -s http://localhost:8080/get_states | jq

curl -X POST "http://localhost:8080/add_target?target=outline.json"
facd_wait

curl -s http://localhost:8080/get_states | jq

#kill "$pid"
