#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/thumbnailer"
[ -f "$CHART/Chart.yaml" ] || hm_fail "thumbnailer/Chart.yaml is missing from the workspace"
dep() { jq -c '[.[] | select(.kind=="Deployment")] | first // {} | {replicas: .spec.replicas, history: .spec.revisionHistoryLimit}'; }

hm_info "Rendering the chart from the workspace..."
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
hm_render_json "$CHART" --set replicaCount=3 >"$HM_TMP/r.json" || hm_fail "helm template fails" "$HM_TMP/render-err.txt"
[ "$(dep <"$HM_TMP/r.json")" = '{"replicas":3,"history":2}' ] || hm_fail "The rendered Deployment has $(dep <"$HM_TMP/r.json"); expected replicas from replicaCount (3 here) and revisionHistoryLimit 2"
hm_ok "The Deployment renders with all its settings"

hm_info "Checking the release..."
hm_require_deployed thumbs
[ "$(hm_release_chart thumbs)" = "thumbnailer-0.6.3" ] || hm_fail "Release thumbs was not deployed from the thumbnailer chart"
[ "$(hm_manifest_json thumbs | dep)" = '{"replicas":2,"history":2}' ] || hm_fail "The release manifest's Deployment is $(hm_manifest_json thumbs | dep)"
hm_wait_rollout deployment/thumbs "$NS" 90s
ready="$(hm_jsonpath deployment/thumbs '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment thumbs has ${ready:-0}/2 ready pods"
[ "$(hm_endpoints_count thumbs)" -ge 2 ] || hm_fail "Service thumbs has fewer than 2 ready endpoints"

hm_pass "thumbs is running with both replicas."
