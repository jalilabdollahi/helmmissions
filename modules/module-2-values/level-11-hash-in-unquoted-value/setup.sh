#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install ledger-api "$SANDBOX/ledger-api" -n "$NS" >/dev/null
pw="$(kubectl get secret ledger-api-db -n "$NS" -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)"
[ "$pw" = "Harbor Light" ] || { echo "setup: expected the truncated password, got '$pw'"; exit 1; }
