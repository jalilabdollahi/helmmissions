#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Last night's pipeline: db install fails in its pre-install hook, api and web were deployed anyway by a second job.
helm install ledger-db "$SANDBOX/ledger-db" -n "$NS" --wait --timeout 45s >/dev/null 2>&1 || true
helm install ledger-api "$SANDBOX/ledger-api" -n "$NS" >/dev/null
helm install ledger-web "$SANDBOX/ledger-web" -n "$NS" --wait --timeout 60s >/dev/null

hm_assert_status ledger-db failed
hm_assert_status ledger-api deployed
hm_assert_status ledger-web deployed
kubectl get job ledger-db-migrate -n "$NS" -o json | jq -e '.status.failed >= 1' >/dev/null || { echo "setup: migration hook did not fail"; exit 1; }
out="$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=ledger-api --no-headers)"
echo "$out" | grep -q "Init" || { echo "setup: api is not stuck in init"; echo "$out"; exit 1; }
