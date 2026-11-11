#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/status-page"
[ -f "$CHART/Chart.yaml" ] || hm_fail "status-page/Chart.yaml is missing from the workspace"
kinds() { jq -c '[.[].kind] | sort'; }

hm_info "Rendering the chart from the workspace..."
hm_render_json "$CHART" >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
[ "$(kinds <"$HM_TMP/r.json")" = '["Deployment","Service"]' ] || hm_fail "The chart renders $(kinds <"$HM_TMP/r.json") instead of a Deployment and a Service"
hm_ok "The chart renders a Deployment and a Service"

hm_info "Checking the release..."
hm_require_deployed status
rev="$(hm_release_revision status)"
[ "${rev:-0}" -ge 2 ] || hm_fail "Release status is still at revision ${rev:-?} - the fixed chart was never deployed"
[ "$(hm_manifest_json status | kinds)" = '["Deployment","Service"]' ] || hm_fail "The release manifest contains $(hm_manifest_json status | kinds)"
kubectl get deployment status -n "$NS" >/dev/null 2>&1 || hm_fail "Deployment status does not exist in the cluster"
hm_wait_rollout deployment/status "$NS" 90s
ready="$(hm_jsonpath deployment/status '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment status has ${ready:-0}/2 ready pods"
[ "$(hm_endpoints_count status)" -ge 2 ] || hm_fail "Service status has fewer than 2 ready endpoints"

hm_pass "The status page is back."
