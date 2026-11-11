#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/geoip"
[ -f "$CHART/Chart.yaml" ] || hm_fail "geoip/Chart.yaml is missing from the workspace"

# lookup container's resources in a rendered/live manifest array on stdin
res() { jq -c '[.[] | select(.kind=="Deployment") | .spec.template.spec.containers[] | select(.name=="lookup") | .resources] | first // {}'; }

hm_info "Rendering the chart from the workspace..."
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
hm_render_json "$CHART" --set resources.limits.memory=96Mi --set resources.requests.cpu=25m >"$HM_TMP/render.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
r="$(res <"$HM_TMP/render.json")"
[ "$(echo "$r" | jq -r '.limits.memory // empty')" = "96Mi" ] && [ "$(echo "$r" | jq -r '.requests.cpu // empty')" = "25m" ] \
  || hm_fail "Rendered container 'lookup' does not carry the resources from the chart values (got: $r)"
hm_ok "The container resources follow the chart values"

hm_info "Checking the release..."
hm_require_deployed geoip
[ "$(hm_release_chart geoip)" = "geoip-1.2.0" ] || hm_fail "Release geoip was not deployed from the geoip chart in the workspace"
live="$(hm_manifest_json geoip | res)"
want="$(hm_yaml_get "$CHART/values.yaml" resources)"
[ "$(echo "$live" | jq -S -c .)" = "$(echo "$want" | jq -S -c .)" ] || hm_fail "The release manifest has resources $live, expected the values-file resources $want"

hm_info "Checking the live pod..."
hm_wait_rollout deployment/geoip-lookup "$NS" 90s
pod_res="$(kubectl get pods -n "$NS" -l app=geoip -o json | jq -c '[.items[0].spec.containers[] | select(.name=="lookup") | .resources] | first')"
[ "$(echo "$pod_res" | jq -r '.limits.memory // empty')" = "$(echo "$want" | jq -r '.limits.memory')" ] \
  || hm_fail "The running pod has no memory limit - resources never reached the container (got: $pod_res)"
[ "$(hm_endpoints_count geoip-lookup)" -ge 1 ] || hm_fail "Service geoip-lookup has no ready endpoints"

hm_pass "geoip-lookup runs with its resources in the right place."
