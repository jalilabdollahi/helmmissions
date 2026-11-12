#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The stack is live, but every component reports REGION=unset.
helm dependency update "$SANDBOX/telemetry" >/dev/null
helm install telemetry "$SANDBOX/telemetry" -n "$NS" --wait --timeout 120s >/dev/null
helm upgrade telemetry "$SANDBOX/telemetry" -n "$NS" --wait --timeout 120s >/dev/null   # the "region" upgrade that changed nothing
hm_assert_status telemetry deployed
for d in gateway collector exporter; do
  v="$(hm_jsonpath "deployment/telemetry-$d" '{.spec.template.spec.containers[0].env[?(@.name=="REGION")].value}')"
  [ "$v" = "unset" ] || { echo "setup: telemetry-$d has REGION='$v', expected the broken 'unset'"; exit 1; }
done
