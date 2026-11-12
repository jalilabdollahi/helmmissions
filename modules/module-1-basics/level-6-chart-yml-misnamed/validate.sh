#!/bin/bash
set -uo pipefail
source "$HM_LIB"

# hm_http_check starts a one-shot pod; retry a few times so a slow kube-proxy sync is not a false negative.
http_retry() {
  local i
  for i in 1 2 3 4 5; do
    hm_http_check "$1" >"$HM_TMP/http.txt" 2>&1 && return 0
    sleep 3
  done
  return 1
}

CHART="$SANDBOX/status-page"

hm_info "Checking the release..."
hm_require_deployed status-page
chart="$(hm_release_chart status-page)"
[ "$chart" = "status-page-0.2.0" ] || hm_fail "Release status-page runs chart '$chart', expected status-page-0.2.0 from the workspace"

hm_info "Checking the chart in your workspace..."
[ -f "$CHART/Chart.yaml" ] || hm_fail "The workspace chart has no chart metadata file Helm can load"
[ ! -e "$CHART/Chart.yml" ] || hm_fail "A leftover Chart.yml is still in the chart folder"
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
hm_ok "Chart metadata file is in place and lint passes"

hm_wait_rollout deployment/status-page "$NS" 90s
[ "$(hm_endpoints_count status-page)" -ge 1 ] || hm_fail "Service status-page has no ready endpoints"
http_retry "http://status-page.$NS.svc/" || hm_fail "The status page does not answer requests"
grep -q "Status" "$HM_TMP/http.txt" || hm_fail "The status page does not serve its HTML"

hm_pass "status-page is up."
