#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Install the broken chart without waiting: the release is "deployed" while the pods cannot start.
helm install receipts "$SANDBOX/receipts" -n "$NS" >/dev/null
for _ in $(seq 1 30); do
  reason="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=receipts -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || true)"
  [ "$reason" = "InvalidImageName" ] && break
  sleep 2
done
[ "$reason" = "InvalidImageName" ] || { echo "setup: pods did not reach InvalidImageName (got: $reason)"; exit 1; }
