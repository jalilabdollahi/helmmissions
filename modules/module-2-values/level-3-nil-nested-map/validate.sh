#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/profile-svc"
[ -f "$CHART/Chart.yaml" ] || hm_fail "profile-svc/Chart.yaml is missing"

hm_info "Rendering the chart with its default values (no cache block)..."
out="$(hm_render_json "$CHART")" || hm_fail "helm template fails without a cache block" "$HM_TMP/render-err.txt"
echo "$out" | jq -e '[.[] | select(.kind=="ConfigMap")] | length == 1' >/dev/null || hm_fail "Expected exactly one ConfigMap in the render"
if echo "$out" | grep -q 'no value'; then hm_fail "The render contains a '<no value>' placeholder"; fi

hm_info "Rendering the chart with the staging values file..."
hm_render_json "$CHART" -f "$SANDBOX/values-staging.yaml" >/dev/null || hm_fail "helm template fails with values-staging.yaml" "$HM_TMP/render-err.txt"

hm_info "Rendering the chart with a cache host..."
out2="$(hm_render_json "$CHART" --set cache.redis.host=redis.verify.example)" || hm_fail "helm template fails when cache.redis.host is set" "$HM_TMP/render-err.txt"
echo "$out2" | jq -e '[.[] | select(.kind=="ConfigMap") | .data | to_entries[] | .value] | any(. == "redis.verify.example")' >/dev/null \
  || hm_fail "With cache.redis.host set, the host does not show up in the rendered ConfigMap any more"
hm_ok "The chart renders with and without the cache block"

hm_require_deployed profile-svc
hm_wait_rollout deployment/profile-svc "$NS" 90s
[ "$(hm_endpoints_count profile-svc)" -ge 1 ] || hm_fail "Service profile-svc has no ready endpoints"
hm_pass "profile-svc runs in staging without a cache."
