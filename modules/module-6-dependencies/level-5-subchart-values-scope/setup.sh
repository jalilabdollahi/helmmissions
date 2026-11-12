#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Revision 1 is already live; the photo desk's numbers (3 replicas, width 800, quality 70) never arrived.
helm dependency update "$SANDBOX/newsroom" >/dev/null
helm install newsroom "$SANDBOX/newsroom" -n "$NS" --wait --timeout 120s >/dev/null
helm upgrade newsroom "$SANDBOX/newsroom" -n "$NS" --wait --timeout 120s >/dev/null   # the engineer's "successful" upgrade
hm_assert_status newsroom deployed
got="$(hm_jsonpath deployment/newsroom-image-resizer '{.spec.replicas}/{.spec.template.spec.containers[0].env[0].value}')"
[ "$got" = "1/1024" ] || { echo "setup: expected the resizer on its defaults (1/1024), got $got"; exit 1; }
