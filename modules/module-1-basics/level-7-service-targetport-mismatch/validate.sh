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

CHART="$SANDBOX/inventory"

hm_info "Checking the service from inside the cluster..."
hm_require_deployed inventory
hm_wait_rollout deployment/inventory "$NS" 90s
[ "$(hm_endpoints_count inventory)" -ge 1 ] || hm_fail "Service inventory has no ready endpoints"
if ! http_retry "http://inventory.$NS.svc/"; then
  hm_fail "A request to http://inventory.$NS.svc/ from inside the cluster fails (connection refused / timeout)"
fi
hm_ok "The Service answers requests"

hm_info "Checking that the fix is part of the release..."
tp="$(hm_manifest_json inventory | jq -r '[.[] | select(.kind=="Service")][0].spec.ports[0].targetPort')"
case "$tp" in 80|http) ;; *) hm_fail "Helm's recorded Service still targets '$tp' - the live object was changed behind Helm's back" ;; esac
rtp="$(hm_render_json "$CHART" | jq -r '[.[] | select(.kind=="Service")][0].spec.ports[0].targetPort')"
case "$rtp" in 80|http) ;; *) hm_fail "The chart in your workspace still renders targetPort '$rtp' - the next upgrade would break it again" ;; esac
hm_ok "Chart and release agree on the target port"

hm_pass "inventory answers again."
