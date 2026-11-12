#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/webapp"

hm_info "Checking Chart.yaml metadata..."
[ -f "$CHART/Chart.yaml" ] || hm_fail "webapp/Chart.yaml is missing from the workspace"
ver="$(hm_yaml_get "$CHART/Chart.yaml" version)"
[ "$ver" = '"0.1.0"' ] || hm_fail "Chart.yaml version is $ver — the chart needs its own SemVer version (0.1.0)"
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
hm_ok "Chart metadata is valid and helm lint passes"

hm_info "Checking the release..."
hm_require_deployed webapp
chart="$(hm_release_chart webapp)"
[ "$chart" = "webapp-0.1.0" ] || hm_fail "Release webapp runs chart '$chart', expected the webapp chart from the workspace"

hm_info "Checking the workload..."
hm_wait_rollout deployment/webapp "$NS" 90s
ready="$(hm_jsonpath deployment/webapp '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment webapp has ${ready:-0}/2 ready pods"
[ "$(hm_endpoints_count webapp)" -ge 2 ] || hm_fail "Service webapp has no ready endpoints"

hm_pass "webapp is live — the chart finally has an identity."
