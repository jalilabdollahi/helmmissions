#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed orders
chart="$(hm_release_chart orders)"
[ "$chart" = "orders-0.2.0" ] || hm_fail "Release orders still runs chart '$chart' - the new chart (0.2.0) is not rolled out"

hm_info "Checking the history..."
hm_history_json orders | jq -e 'map(select(.chart=="orders-0.1.0")) | length >= 1' >/dev/null \
  || hm_fail "The history of 'orders' no longer contains the 0.1.0 revision - the release was deleted and recreated, so it cannot be rolled back"
rev="$(hm_release_revision orders)"
[ "${rev:-0}" -ge 2 ] || hm_fail "Release orders is at revision ${rev:-?}; expected an upgrade on top of the running one"
hm_ok "History preserved: $(hm_history_json orders | jq -r 'map(.chart) | join(" -> ")')"

hm_info "Checking the workload..."
hm_wait_rollout deployment/orders "$NS" 90s
ready="$(hm_jsonpath deployment/orders '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment orders has ${ready:-0}/2 ready pods"
v="$(hm_jsonpath configmap/orders-config '{.data.PAYMENT_TIMEOUT_SECONDS}')"
[ "$v" = "45" ] || hm_fail "ConfigMap orders-config from the new chart is missing or wrong (got '${v:-none}')"

hm_pass "orders runs chart 0.2.0 with its history intact."
