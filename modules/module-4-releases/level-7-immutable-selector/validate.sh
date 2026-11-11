#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed catalog-search
hist="$(hm_history_json catalog-search)"
[ "$(echo "$hist" | jq -r '.[0].revision')" = "1" ] || hm_fail "Revision 1 is gone from the history — the release was recreated instead of upgraded"
[ "$(hm_release_chart catalog-search)" = "catalog-search-1.1.0" ] \
  || hm_fail "Release runs '$(hm_release_chart catalog-search)', expected catalog-search-1.1.0"

hm_info "Checking the Deployment selector..."
sel="$(kubectl get deployment catalog-search -n "$NS" -o json 2>/dev/null | jq -c '.spec.selector.matchLabels // {}')"
[ "$sel" = '{"app":"catalog-search"}' ] || hm_fail "The Deployment selector is $sel — it must stay what 1.0 created ({\"app\":\"catalog-search\"})"
hm_wait_rollout deployment/catalog-search "$NS" 90s
ready="$(hm_jsonpath deployment/catalog-search '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment catalog-search has ${ready:-0}/2 ready pods"
labelled="$(kubectl get pods -n "$NS" -l app=catalog-search,app.kubernetes.io/name=catalog-search --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d ' ')"
[ "$labelled" -ge 2 ] || hm_fail "Only $labelled running pods carry the new app.kubernetes.io/name label"
[ "$(hm_endpoints_count catalog-search)" -ge 2 ] || hm_fail "Service catalog-search has fewer than 2 ready endpoints"

hm_pass "catalog-search 1.1 is live with the new labels and an untouched selector."
