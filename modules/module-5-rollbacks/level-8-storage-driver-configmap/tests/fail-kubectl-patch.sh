#!/bin/bash
# Wrong fix: remove the bad args from the live Deployment - pod recovers, release record still says revision 2.
set -euo pipefail
source "$HM_LIB"

kubectl patch deployment audit-gateway -n "$NS" --type=json -p '[{"op":"remove","path":"/spec/template/spec/containers/0/args"}]'
kubectl rollout status deployment/audit-gateway -n "$NS" --timeout=90s
