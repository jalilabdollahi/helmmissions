#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The release is installed WITHOUT --wait, so it is "deployed" while its pods cannot start.
helm install ledger-api "$SANDBOX/ledger-api" -n "$NS" >/dev/null

for _ in $(seq 1 60); do
  reason="$(kubectl get pods -n "$NS" -l app=ledger-api -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' 2>/dev/null || true)"
  case "$reason" in *ErrImagePull*|*ImagePullBackOff*) exit 0 ;; esac
  sleep 2
done
echo "setup: pods never reached an image pull failure"; exit 1
