#!/bin/bash

# The checks will all fail if there are uncommitted files in the repo.
# We therefore ensure there are no uncommitted files before performing the tests.
if ! [ -z "$(git status --porcelain)" ]; then
    echo 'ERROR: The git repo is not clean (i.e. you may have uncommitted files), but the test script requires a clean repo. You should either commit the files or delete them.'
    echo 'HINT: You can delete all uncommitted files with the `git clean -fd` command.'
    exit 1
fi

dotest() {
    mkdir -p .results
    cat > .results/"$1"
    diff .results/"$1" .expected/"$1"
}

clean_repo() {
    git clean -fd -e .results/
}

curl_add_target() {
    curl -X POST "http://localhost:8080/add_target" -H "Content-Type: application/json" -d "{\"target\":\"$1\"}"
}

set -ex

################################################################################
# tests start here
################################################################################

# ensure there are no other servers running,
# then start the server
killall facd || true
facd --auto_commit=False &
pid=$!

./facd_wait.sh
curl -s http://localhost:8080/context_states | jq | dotest checkpoint1

curl_add_target 'outline.json'
./facd_wait.sh
curl -s http://localhost:8080/context_states | jq | dotest checkpoint2

curl_add_target 'sub0003/sub0002/outline.json'
./facd_wait.sh
curl -s http://localhost:8080/context_states | jq | dotest checkpoint3

# we perform a bunch of repeated rm/build combos
# and ensure that we always get back to the same internal state;
# notice the repeated use of checkpoint3 to ensure that the
# internal state remains consistent no matter how we got here
for i in 1 2 3 4 5; do

    rm sub0003/outline.json
    sleep 1
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint4a

    curl_add_target 'sub0003/sub0002/outline.json'
    ./facd_wait.sh
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint3

    rm outline.json
    sleep 1
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint4b

    curl_add_target 'sub0003/sub0002/outline.json'
    ./facd_wait.sh
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint3

    rm sub0003/sub0002/outline.json
    sleep 1
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint4c

    curl_add_target 'sub0003/sub0002/outline.json'
    ./facd_wait.sh
    curl -s http://localhost:8080/context_states | jq | dotest checkpoint3
done

curl -X POST 'http://localhost:8080/add_target' -H 'Content-Type: application/json' -d '{"target":"sub$LEVEL1/sub$LEVEL2/outline.json"}'
./facd_wait.sh
curl -s http://localhost:8080/context_states | jq | dotest checkpoint6

curl -X POST 'http://localhost:8080/add_target' -H 'Content-Type: application/json' -d '{"target":"final.txt"}'
./facd_wait.sh
curl -s http://localhost:8080/context_states | jq | dotest checkpoint7

clean_repo
kill "$pid"
