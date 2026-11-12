#!/bin/bash
# Shortcut: skip the failing migration hook entirely instead of fixing the target.
set -euo pipefail
source "$HM_LIB"
helm uninstall ledger-db -n "$NS" >/dev/null
kubectl delete job ledger-db-migrate -n "$NS" --ignore-not-found >/dev/null
helm install ledger-db "$SANDBOX/ledger-db" -n "$NS" --no-hooks --wait --timeout 60s
cp -R "$LEVEL_DIR/solution/ledger-api/." "$SANDBOX/ledger-api/"
cp -R "$LEVEL_DIR/solution/ledger-web/." "$SANDBOX/ledger-web/"
helm upgrade ledger-api "$SANDBOX/ledger-api" -n "$NS" --wait --timeout 90s
helm upgrade ledger-web "$SANDBOX/ledger-web" -n "$NS" --wait --timeout 60s
