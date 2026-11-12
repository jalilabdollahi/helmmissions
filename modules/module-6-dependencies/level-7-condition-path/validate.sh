#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/helpdesk"

hm_info "Checking the chart keeps a working on/off switch for the subchart..."
cond="$(hm_yaml_get "$CHART/Chart.yaml" dependencies | jq -r '[.[] | select(.name=="ticket-search")][0].condition // ""')"
[ -n "$cond" ] || hm_fail "helpdesk/Chart.yaml no longer declares ticket-search with a condition"
off="$(hm_render_json "$CHART" | jq '[.[] | select((.metadata.name // "") | test("ticket-search"))] | length')"
[ "${off:-1}" = "0" ] || hm_fail "Rendering the chart with its default values (search.enabled: false) still produces $off ticket-search objects"
on="$(hm_render_json "$CHART" --set "$cond=true" | jq '[.[] | select((.metadata.name // "") | test("ticket-search"))] | length')"
[ "${on:-0}" -ge 1 ] || hm_fail "Setting $cond=true does not bring the search subchart back — the switch does not control the dependency"
hm_ok "The chart omits the search subchart by default and brings it back with $cond=true"

hm_info "Checking the release..."
hm_require_deployed helpdesk
[ "$(hm_release_revision helpdesk)" -ge 2 ] || hm_fail "Release helpdesk is still on its first revision — nothing was rolled out"
hm_manifest_json helpdesk | jq -e 'any(.[]; (.metadata.name // "") | test("ticket-search"))' >/dev/null \
  && hm_fail "The helpdesk release still contains ticket-search objects (helm get manifest helpdesk)"
kubectl get deployment helpdesk-ticket-search -n "$NS" >/dev/null 2>&1 && hm_fail "Deployment helpdesk-ticket-search is still running in the cluster"
kubectl get service helpdesk-ticket-search -n "$NS" >/dev/null 2>&1 && hm_fail "Service helpdesk-ticket-search is still in the cluster"
hm_ok "The search subchart is gone from the release"

hm_wait_rollout deployment/helpdesk-web "$NS" 90s
hm_pass "helpdesk runs without the search subchart, and the switch works."
