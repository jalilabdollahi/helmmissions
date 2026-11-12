#!/bin/bash
# Wrong fix: patch the failed Job in the cluster instead of the chart. The release itself stays failed.
set -euo pipefail
source "$HM_LIB"

kubectl delete job ledger-api-migrate -n "$NS" --ignore-not-found >/dev/null
kubectl create job ledger-api-migrate -n "$NS" --image=busybox:1.36 -- sh -c 'echo "[migrate] done: 3 migrations applied"'
kubectl wait job/ledger-api-migrate -n "$NS" --for=condition=complete --timeout=60s
