#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/statuspage"

hm_info "Checking the dependency was resolved..."
hm_yaml_get "$CHART/Chart.yaml" dependencies | jq -e 'any(.[]; .name=="uptime-probe")' >/dev/null \
  || hm_fail "statuspage/Chart.yaml no longer declares uptime-probe"
locked="$(hm_yaml_get "$CHART/Chart.lock" dependencies.0.version | jq -r '. // ""')"
[ -n "$locked" ] || hm_fail "There is no Chart.lock entry for uptime-probe — the dependency was never resolved from a repository"
[ -f "$CHART/charts/uptime-probe-$locked.tgz" ] || hm_fail "charts/ does not contain uptime-probe-$locked.tgz that Chart.lock names"
echo "$locked" | grep -q '^1\.4\.' || hm_fail "Chart.lock pins uptime-probe $locked, but statuspage needs the 1.4 line"
repo="$(hm_yaml_get "$CHART/Chart.yaml" dependencies.0.repository | jq -r '.')"
case "$repo" in
  @*) name="${repo#@}"
      helm repo list -o json 2>/dev/null | jq -e --arg n "$name" --arg u "$HM_CHARTREPO_URL/m6-repo-not-added" 'any(.[]; .name==$n and (.url|rtrimstr("/"))==$u)' >/dev/null \
        || hm_fail "Chart.yaml refers to repository $repo, but no repo with that name pointing at the platform team's repository is configured" ;;
  http*) [ "${repo%/}" = "$HM_CHARTREPO_URL/m6-repo-not-added" ] || hm_fail "uptime-probe repository is '$repo', not the platform team's repository" ;;
  *) hm_fail "Unexpected repository '$repo' for uptime-probe" ;;
esac
hm_ok "uptime-probe $locked was resolved from the platform repository"

hm_info "Checking the release..."
hm_require_deployed statuspage
chart="$(hm_release_chart statuspage)"
[ "$chart" = "statuspage-1.1.0" ] || hm_fail "Release statuspage runs chart '$chart', expected statuspage-1.1.0"
v="$(hm_manifest_json statuspage | jq -r '[.[] | select(.kind=="Deployment" and .metadata.name=="statuspage-uptime-probe")][0].metadata.labels["helm.sh/chart"] // ""')"
[ "$v" = "uptime-probe-$locked" ] || hm_fail "The release contains '${v:-no probe}', expected uptime-probe-$locked"
hm_wait_rollout deployment/statuspage "$NS" 90s
hm_wait_rollout deployment/statuspage-uptime-probe "$NS" 90s
hm_pass "statuspage is live with its uptime probe."
