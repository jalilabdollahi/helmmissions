#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install telemetry-agent "$SANDBOX/telemetry-agent" -n "$NS" \
  --set podAnnotations.prometheus.io/scrape=true \
  --set podAnnotations.prometheus.io/port=9100 --wait --timeout 120s >/dev/null
a="$(kubectl get deploy telemetry-agent -n "$NS" -o json | jq -r '.spec.template.metadata.annotations | keys | join(",")')"
[ "$a" = "prometheus" ] || { echo "setup: expected the junk annotation 'prometheus', got '$a'"; exit 1; }
