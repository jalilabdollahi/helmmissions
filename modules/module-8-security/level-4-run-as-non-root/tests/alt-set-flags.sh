#!/bin/bash
# Valid alternative: no file edits, override the image and port on the command line.
set -euo pipefail
source "$HM_LIB"

helm upgrade status-page ./status-page -n "$NS" --set image.repository=nginxinc/nginx-unprivileged --set containerPort=8080 --wait --timeout 120s
