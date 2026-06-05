#!/bin/bash

# These tests ensure that:
# 1. Removing files correctly places reverse dependencies into stale states.
# 2. Subsequent builds work correctly when contexts are stale.

source ../framework.sh
facd_start

facd_wait
curl -s http://localhost:8080/context_states | jq | dotest checkpoint1

facd_add_target 'outline.json'
facd_wait
curl -s http://localhost:8080/context_states | jq | dotest checkpoint2

facd_add_target 'sub0003/sub0002/outline.json'
facd_wait
curl -s http://localhost:8080/context_states | jq | dotest checkpoint3

# we perform a bunch of repeated rm/build combos
# and ensure that we always get back to the same internal state;
# notice the repeated use of checkpoint3 to ensure that the
# internal state remains consistent no matter how we got here
for i in 1 2 3 4 5; do

    rm sub0003/outline.json
    sleep 1
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint4a

    facd_add_target 'sub0003/sub0002/outline.json'
    facd_wait
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint3

    rm outline.json
    sleep 1
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint4b

    facd_add_target 'sub0003/sub0002/outline.json'
    facd_wait
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint3

    rm sub0003/sub0002/outline.json
    sleep 1
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint4c

    facd_add_target 'sub0003/sub0002/outline.json'
    facd_wait
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint3
done

curl -X POST 'http://localhost:8080/add_target' -H 'Content-Type: application/json' -d '{"target":"sub$LEVEL1/sub$LEVEL2/outline.json"}'
facd_wait
curl -s http://localhost:8080/context_states | jq | dotest checkpoint6

curl -X POST 'http://localhost:8080/add_target' -H 'Content-Type: application/json' -d '{"target":"final.txt"}'
facd_wait
curl -s http://localhost:8080/context_states | jq | dotest checkpoint7

finalize_tests
