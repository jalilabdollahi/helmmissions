#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/echo-api"
[ -f "$CHART/Chart.yaml" ] || hm_fail "echo-api/Chart.yaml is missing from the workspace"
img() { jq -r '[.[] | select(.kind=="Deployment") | .spec.template.spec.containers[0].image] | first // empty'; }
pinned="$(hm_yaml_get "$CHART/values.yaml" image.tag | jq -r .)"
app="$(hm_yaml_get "$CHART/Chart.yaml" appVersion | jq -r .)"

hm_info "Rendering the chart under different values..."
hm_render_json "$CHART" >"$HM_TMP/a.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
[ "$(img <"$HM_TMP/a.json")" = "traefik/whoami:$pinned" ] || hm_fail "With default values the chart renders '$(img <"$HM_TMP/a.json")', expected the pinned tag '$pinned'"
hm_render_json "$CHART" --set image.tag=does-not-exist >"$HM_TMP/b.json" || hm_fail "helm template fails with --set"
[ "$(img <"$HM_TMP/b.json")" = "traefik/whoami:does-not-exist" ] || hm_fail "An explicit image.tag is ignored (rendered '$(img <"$HM_TMP/b.json")')"
hm_render_json "$CHART" --set image.tag= >"$HM_TMP/c.json" || hm_fail "helm template fails with empty tag"
[ "$(img <"$HM_TMP/c.json")" = "traefik/whoami:$app" ] || hm_fail "With an empty image.tag the chart renders '$(img <"$HM_TMP/c.json")', expected the appVersion fallback '$app'"
hm_ok "Pinned tag wins, empty tag falls back to appVersion"

hm_info "Checking the release..."
hm_require_deployed echo
rev="$(hm_release_revision echo)"
[ "${rev:-0}" -ge 2 ] || hm_fail "Release echo is still at revision ${rev:-?} - the fix was never deployed"
[ "$(hm_manifest_json echo | img)" = "traefik/whoami:$pinned" ] || hm_fail "The release manifest still runs '$(hm_manifest_json echo | img)'"
hm_wait_rollout deployment/echo "$NS" 90s
ready="$(hm_jsonpath deployment/echo '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment echo has ${ready:-0}/2 ready pods"
[ "$(hm_endpoints_count echo)" -ge 2 ] || hm_fail "Service echo has fewer than 2 ready endpoints"

hm_pass "echo runs the pinned image again."
