#! /usr/bin/env bash

# This scripts deploys a new version of the application with zero downtime.
# It assumes that the application binary is located at ./bin/nodowntime
# and that it listens on ports 5555 and 5556.
# It also assumes that nginx is configured to proxy requests to the application
# and that the nginx configuration file is located at ./nginx.conf.
# The nginx configuration should have a symbolic to link to /etc/nginx/sites-enabled/
# and should be reloaded after updating the configuration.
#
# For a brief time, both the old and new instances will be running,
# but nginx will only route traffic to one.

set -euo pipefail

app_bin=./bin/nodowntime
ports=(5555 5556)
old_port=
new_port=

# find the old port
for port in "${ports[@]}"; do
    if lsof -i :"$port" &>/dev/null; then
        old_port=$port
        break
    fi
done

for port in "${ports[@]}"; do
    if [[ "$port" != "$old_port" ]]; then
        if ! lsof -i :"$port" &>/dev/null; then
            new_port=$port
            break
        fi
    fi
done

if [[ -z "$old_port" ]]; then
    echo "No old instance found. Starting new instance on port ${ports[0]}."
    new_port=${ports[0]}
fi

if [[ -z "$new_port" ]]; then
    echo "No free port found. Exiting."
    exit 1
fi

echo "Using port: $new_port"

PORT="$new_port" $app_bin &
new_pid=$!

echo "Started new instance with PID: $new_pid"

# wait until the new instance is healthy
until curl -fsSL "http://localhost:$new_port/health" &>/dev/null; do
    echo "Waiting for new instance to become healthy..."
    sleep 0.5
done

echo "New instance is healthy."

nginx_conf="./nginx.conf"
sudo sed -i -E "s|server localhost:$old_port;|server localhost:$new_port;|" "$nginx_conf"

sudo systemctl reload nginx

# kill the old instance
if [[ -n "$old_port" ]]; then
    old_pid=$(lsof -ti :"$old_port")
    echo "Killing old instance with PID: $old_pid"
    kill "$old_pid"
else
    old_pid=
fi
