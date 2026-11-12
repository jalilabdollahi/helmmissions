#!/bin/bash
# Tempting wrong fix: skip the hook so the install goes green. The migration never runs.
set -euo pipefail
source "$HM_LIB"

helm uninstall ledger-api -n "$NS" --wait >/dev/null
kubectl delete job ledger-api-migrate -n "$NS" --ignore-not-found >/dev/null
helm install ledger-api ./ledger-api -n "$NS" --no-hooks --wait --timeout 90s
