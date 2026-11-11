#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install tsdb "$LEVEL_DIR/assets/timeseries-db" -n "$NS" --wait --timeout 120s >/dev/null
kubectl exec statefulset/tsdb -n "$NS" -- sh -c 'echo "six months of telemetry" > /data/marker'
helm upgrade tsdb "$SANDBOX/timeseries-db" -n "$NS" >"$HM_TMP/up.txt" 2>&1 && { echo "setup: upgrade unexpectedly succeeded"; exit 1; }
grep -q "volumeClaimTemplates" "$HM_TMP/up.txt" || { cat "$HM_TMP/up.txt"; exit 1; }
hm_assert_status tsdb failed
