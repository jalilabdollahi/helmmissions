#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/geo-lookup"

hm_info "Checking the configuration the pipeline would deploy..."
[ -f "$SANDBOX/values-prod.yaml" ] || hm_fail "values-prod.yaml is missing from the workspace"
conf="$(hm_render_json "$CHART" -f "$SANDBOX/values-prod.yaml" | jq -r '[.[]|select(.kind=="ConfigMap")][0].data["default.conf"]')" || hm_fail "The chart does not render with values-prod.yaml" "$HM_TMP/render-err.txt"
echo "$conf" | grep -q '"provider":"maps-v2","ttl":300,"trace":false' \
  || hm_fail "Chart + values-prod.yaml would deploy a configuration that is not the good one - the next pipeline run would break it again"
hm_ok "Chart + values-prod.yaml render the good configuration"

hm_info "Checking the release..."
hm_require_deployed geo-lookup
[ "$(hm_release_revision geo-lookup)" -ge 5 ] || hm_fail "Release is still on revision $(hm_release_revision geo-lookup) - nothing new was deployed"
case "$(hm_release_description geo-lookup)" in Rollback*) hm_fail "The newest revision is a rollback to a revision that is itself broken" ;; esac

hm_info "Checking the service..."
hm_wait_rollout deployment/geo-lookup "$NS" 90s
hm_http_check http://geo-lookup/lookup >"$HM_TMP/body.txt" || hm_fail "GET /lookup does not return 200 (it is still failing)"
grep -q '"provider":"maps-v2","ttl":300,"trace":false' "$HM_TMP/body.txt" || hm_fail "GET /lookup answers with the wrong configuration" "$HM_TMP/body.txt"

hm_pass "geo-lookup is back on the good configuration - fixed forward."
