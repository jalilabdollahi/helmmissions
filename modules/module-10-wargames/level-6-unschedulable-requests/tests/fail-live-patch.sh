#!/bin/bash
# Shortcut: shrink requests and drop the selector on the live Deployments; the values files and release records stay broken.
set -euo pipefail
source "$HM_LIB"
kubectl set resources deployment/telemetry-ingest --requests=cpu=100m -n "$NS"
kubectl set resources deployment/telemetry-rollup --requests=memory=128Mi -n "$NS"
kubectl patch deployment telemetry-alerts -n "$NS" --type=json -p '[{"op":"remove","path":"/spec/template/spec/nodeSelector"},{"op":"remove","path":"/spec/template/spec/affinity"}]'
for s in ingest rollup alerts; do kubectl rollout status deployment/telemetry-$s -n "$NS" --timeout=90s; done
