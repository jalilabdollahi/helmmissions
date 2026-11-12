#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed loyalty-points
hist="$(hm_history_json loyalty-points)"
[ "$(echo "$hist" | jq -r '.[0].revision')" = "1" ] || hm_fail "The release history was lost — the original revisions are gone"
[ "$(echo "$hist" | jq 'length')" -ge 3 ] || hm_fail "The release has no new revision on top of the old history"
case "$(echo "$hist" | jq -r '.[-1].description')" in
  "Rollback to "*) ;;
  *) hm_fail "The newest revision is '$(echo "$hist" | jq -r '.[-1].description')', not a rollback of the old history" ;;
esac
chart="$(hm_release_chart loyalty-points)"
[ "$chart" = "loyalty-points-1.1.0" ] || hm_fail "Release runs '$chart' — that is not the configuration it had when it was uninstalled"

hm_info "Checking the restored workload..."
hm_wait_rollout deployment/loyalty-points "$NS" 90s
[ "$(hm_jsonpath deployment/loyalty-points '{.status.readyReplicas}')" = "2" ] || hm_fail "Deployment loyalty-points does not have 2 ready replicas"
kubectl get deployment loyalty-points -n "$NS" -o json | jq -e '.spec.template.spec.containers[0].env | any(.[]; .name=="TIER_GOLD_THRESHOLD" and .value=="500")' >/dev/null \
  || hm_fail "TIER_GOLD_THRESHOLD is not 500 — values from the last deploy are missing"
[ "$(hm_endpoints_count loyalty-points)" -ge 2 ] || hm_fail "Service loyalty-points has fewer than 2 ready endpoints"

hm_pass "loyalty-points is back exactly as it was before the uninstall."
