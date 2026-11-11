#!/bin/bash
set -euo pipefail
source "$HM_LIB"

C="$SANDBOX/ticket-booking"
# rev 1: blue live, green parked at 0 replicas
helm install ticket-booking "$C" -n "$NS" --set activeColor=blue --wait --timeout 90s >/dev/null
# rev 2: release 6.1 on green with an image that can't be pulled, traffic switched (no --wait)
helm upgrade ticket-booking "$C" -n "$NS" --reset-values -f "$SANDBOX/values-prod.yaml" >/dev/null

hm_assert_status ticket-booking deployed
[ "$(hm_release_revision ticket-booking)" = "2" ] || { echo "setup: expected revision 2"; exit 1; }
[ "$(hm_jsonpath service/ticket-booking '{.spec.selector.color}')" = "green" ] || { echo "setup: service does not select green"; exit 1; }
[ "$(hm_endpoints_count ticket-booking)" = "0" ] || { echo "setup: service still has endpoints"; exit 1; }
