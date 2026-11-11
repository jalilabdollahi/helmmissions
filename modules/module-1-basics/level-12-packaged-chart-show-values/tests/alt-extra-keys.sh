#!/bin/bash
# Valid: values file with more than the minimum.
set -euo pipefail
source "$HM_LIB"

cat >"$SANDBOX/probe-values.yaml" <<'YAML'
replicaCount: 1
telemetry:
  servicePort: 9100
  scrapeInterval: 15s
YAML
helm install node-probe vendor/node-probe-0.4.2.tgz -n "$NS" -f probe-values.yaml --wait --timeout 120s
