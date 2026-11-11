#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/edge-throttle"

hm_info "Checking that the chart restarts pods when configuration changes..."
a="$(hm_render_json "$CHART" --set rateLimit=100 | jq -c '[.[]|select(.kind=="Deployment")][0].spec.template')" || hm_fail "The chart does not render" "$HM_TMP/render-err.txt"
b="$(hm_render_json "$CHART" --set rateLimit=250 | jq -c '[.[]|select(.kind=="Deployment")][0].spec.template')" || hm_fail "The chart does not render" "$HM_TMP/render-err.txt"
[ "$a" != "$b" ] || hm_fail "Changing rateLimit does not change the Deployment's pod template - Helm will update the ConfigMap but never restart the pods"
hm_ok "A config change alters the pod template"

hm_info "Checking the release..."
hm_require_deployed edge-throttle
[ "$(hm_release_revision edge-throttle)" -ge 4 ] || hm_fail "Release is still on revision $(hm_release_revision edge-throttle) - the chart fix was never deployed"
[ "$(hm_jsonpath configmap/edge-throttle-config '{.data.RATE_LIMIT}')" = "100" ] || hm_fail "The ConfigMap does not say RATE_LIMIT=100"

hm_info "Checking what the pods actually run with..."
hm_wait_rollout deployment/edge-throttle "$NS" 90s
for _ in 1 2 3 4; do
  hm_http_check http://edge-throttle >"$HM_TMP/body.txt" || hm_fail "http://edge-throttle does not answer"
  grep -q "rate_limit=100 " "$HM_TMP/body.txt" && break
  sleep 3
done
grep -q "rate_limit=100 " "$HM_TMP/body.txt" || hm_fail "The pods still run with stale configuration" "$HM_TMP/body.txt"

hm_pass "Config and pods agree, and the chart now keeps them in sync."
