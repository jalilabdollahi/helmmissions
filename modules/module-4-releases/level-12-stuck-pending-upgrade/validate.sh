#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release state..."
st="$(hm_release_status warehouse-stock)"
case "$st" in
  pending-*) hm_fail "Release warehouse-stock is still '$st' — every new operation will be refused" ;;
esac
hm_require_deployed warehouse-stock
hist="$(hm_history_json warehouse-stock)"
[ "$(echo "$hist" | jq -r '.[-1].description')" != "Preparing upgrade" ] || hm_fail "The newest revision is the interrupted one"
[ "$(hm_release_chart warehouse-stock)" = "warehouse-stock-1.1.0" ] \
  || hm_fail "Release runs '$(hm_release_chart warehouse-stock)', expected warehouse-stock-1.1.0 from the workspace"

hm_info "Checking the 1.1 workload..."
hm_wait_rollout deployment/warehouse-stock "$NS" 90s
[ "$(hm_jsonpath deployment/warehouse-stock '{.status.readyReplicas}')" = "2" ] || hm_fail "Deployment warehouse-stock does not have 2 ready replicas"
kubectl get deployment warehouse-stock -n "$NS" -o json | jq -e '.spec.template.spec.containers[0].env | any(.[]; .name=="SYNC_INTERVAL_SECONDS" and .value=="30")' >/dev/null \
  || hm_fail "SYNC_INTERVAL_SECONDS=30 from chart 1.1 is not live"

hm_info "Proving the pipeline can deploy again..."
helm upgrade warehouse-stock "$SANDBOX/warehouse-stock" -n "$NS" --wait --timeout 60s >"$HM_TMP/again.txt" 2>&1 \
  || hm_fail "A new upgrade is still refused or failing" "$HM_TMP/again.txt"

hm_pass "warehouse-stock is unlocked and running 1.1."
