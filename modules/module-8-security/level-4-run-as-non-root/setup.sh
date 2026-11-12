#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade --install status-page "$SANDBOX/status-page" -n "$NS" >/dev/null
hm_assert_status status-page deployed
for _ in $(seq 1 40); do
  reason="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=status-page -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || true)"
  [ "$reason" = CreateContainerConfigError ] && exit 0
  sleep 2
done
echo "setup: pods did not reach CreateContainerConfigError (got '${reason:-none}')"; exit 1
