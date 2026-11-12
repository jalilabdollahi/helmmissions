#!/bin/bash
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
# revision 1: version 1.0 with the chart's defaults, healthy
for svc in ingest rollup alerts; do
  helm install "telemetry-$svc" ./telemetry -n "$NS" --wait --timeout 60s >/dev/null
done
# revision 2: last night's release with the values files from the workspace
for svc in ingest rollup alerts; do
  helm upgrade "telemetry-$svc" ./telemetry -n "$NS" -f "values/$svc.yaml" --wait --timeout 12s >/dev/null 2>&1 || true
done
for svc in ingest rollup alerts; do hm_assert_status "telemetry-$svc" failed; done
pending="$(kubectl get pods -n "$NS" --no-headers | grep -c Pending || true)"
[ "$pending" -ge 3 ] || { echo "setup: expected Pending pods, found $pending"; kubectl get pods -n "$NS"; exit 1; }
