#!/bin/sh

# this script waits until facd is in a "stable" state
# where all jobs have finished

HOST=localhost:8080
TIMEOUT=20

sleep 1
for i in $(seq 1 $TIMEOUT); do
  sleep 1
  response=$(curl -s "$HOST"/job_states) || { sleep 1; continue; }
  queued=$(echo "$response" | jq '.queued | length')
  running=$(echo "$response" | jq '.running | length')
  if [ "$queued" -eq 0 ] && [ "$running" -eq 0 ]; then
    exit 0
  fi
  echo "facd_wait; i=$i"
done

echo "facd_wait() exceeded TIMEOUT=$TIMEOUT"
exit 1
