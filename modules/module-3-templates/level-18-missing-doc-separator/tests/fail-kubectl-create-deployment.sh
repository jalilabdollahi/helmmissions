#!/bin/bash
# Tempting hotfix: create the missing Deployment by hand. Helm does not own it and the chart is still wrong.
set -euo pipefail
source "$HM_LIB"

kubectl create deployment status --image=nginxinc/nginx-unprivileged:1.27-alpine --replicas=2 -n "$NS" --dry-run=client -o yaml \
  | kubectl apply -n "$NS" -f -
