#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# tags.monitoring=false is set, yet one monitoring component is still running.
helm dependency update "$SANDBOX/tradedesk" >/dev/null
helm install tradedesk "$SANDBOX/tradedesk" -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status tradedesk deployed
for d in tradedesk-metrics-agent tradedesk-trace-collector; do
  ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1 || { echo "setup: $d should be off already"; exit 1; }
done
kubectl get deployment tradedesk-log-shipper -n "$NS" >/dev/null 2>&1 || { echo "setup: log-shipper should be the straggler"; exit 1; }
