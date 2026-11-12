#!/bin/bash
# Wrong fix: repeat the hotfix. It works until the next deploy - Git still says 5.
set -euo pipefail
source "$HM_LIB"

kubectl set env deployment/order-sync DB_POOL_SIZE=40 -n "$NS"
kubectl rollout status deployment/order-sync -n "$NS" --timeout=90s
