#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install ingest "$SANDBOX/ingest" -n "$NS" >/dev/null
for _ in $(seq 1 45); do
  restarts="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=ingest -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null || true)"
  [ "${restarts:-0}" -ge 1 ] && break
  sleep 2
done
[ "${restarts:-0}" -ge 1 ] || { echo "setup: the pod did not start crash-looping"; exit 1; }
