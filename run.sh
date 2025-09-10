#! /usr/bin/env bash

# This script continuously checks the health endpoint of a service running on localhost:4444
while true; do
    res=$(curl -fsSL http://localhost:4444/health || echo "unreachable")
    echo $(date "+%Y-%m-%d %H:%M:%S") $res
    sleep 0.1
done
