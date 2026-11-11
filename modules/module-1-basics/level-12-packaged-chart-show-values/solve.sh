#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# What a player does: read the chart's values, then write a values file.
helm show values vendor/node-probe-0.4.2.tgz >/dev/null
printf 'telemetry:\n  servicePort: 9100\n' >probe-values.yaml
helm install node-probe vendor/node-probe-0.4.2.tgz -n "$NS" -f probe-values.yaml --wait --timeout 120s
