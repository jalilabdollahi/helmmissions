#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/receipts"
[ -f "$CHART/Chart.yaml" ] || hm_fail "receipts/Chart.yaml is missing from the workspace"
img() { jq -r '[.[] | select(.kind=="Deployment") | .spec.template.spec.containers[0].image] | first // empty'; }

hm_info "Rendering the chart from the workspace..."
hm_render_json "$CHART" >"$HM_TMP/r1.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
[ "$(img <"$HM_TMP/r1.json")" = "nginx:1.27-alpine" ] || hm_fail "The chart renders image '$(img <"$HM_TMP/r1.json")', expected nginx:1.27-alpine"
hm_render_json "$CHART" --set image.repository=busybox --set image.tag=1.36 >"$HM_TMP/r2.json" || hm_fail "helm template fails with overrides"
[ "$(img <"$HM_TMP/r2.json")" = "busybox:1.36" ] || hm_fail "Overriding image.repository / image.tag does not change the rendered image (got '$(img <"$HM_TMP/r2.json")')"
hm_ok "The image reference follows image.repository and image.tag"

hm_info "Checking the release..."
hm_require_deployed receipts
rev="$(hm_release_revision receipts)"
[ "${rev:-0}" -ge 2 ] || hm_fail "Release receipts is still at revision ${rev:-?} - the fixed chart was never deployed"
[ "$(hm_manifest_json receipts | img)" = "nginx:1.27-alpine" ] || hm_fail "The deployed release manifest still has image '$(hm_manifest_json receipts | img)'"

hm_info "Checking the workload..."
hm_wait_rollout deployment/receipts-api "$NS" 90s
ready="$(hm_jsonpath deployment/receipts-api '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment receipts-api has ${ready:-0}/2 ready pods"
live="$(hm_jsonpath deployment/receipts-api '{.spec.template.spec.containers[0].image}')"
[ "$live" = "nginx:1.27-alpine" ] || hm_fail "Live Deployment image is '$live'"
[ "$(hm_endpoints_count receipts-api)" -ge 2 ] || hm_fail "Service receipts-api has fewer than 2 ready endpoints"

hm_pass "receipts-api is serving again."
