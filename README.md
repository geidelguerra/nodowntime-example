# Simple no downtime example using NGINX with a Go HTTP server.

## How it works

It works by rotating between to ports when deploying a new version. Inside `deploy.sh` file you can see that we have and array of ports defined.
Each time we deploy a new version the `deploy.sh` scripts updates the `nginx.conf` file to use the new port and then reload NGINX.
Each new version runs on the port that is not currently being used by NGINX.
