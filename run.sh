#! /usr/bin/env bash

while true; do
    res=$(curl -fsSL http://localhost:4444/health || echo "unreachable")
    echo $(date "+%Y-%m-%d %H:%M:%S") $res
    sleep 0.1
done
