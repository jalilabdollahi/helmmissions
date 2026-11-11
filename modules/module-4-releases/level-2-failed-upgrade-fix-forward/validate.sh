#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed ledger-sync
hist="$(hm_history_json ledger-sync)"
latest="$(echo "$hist" | jq -r '.[-1].revision')"
[ "$latest" -ge 3 ] || hm_fail "The release is on revision $latest — the fix has to be a new revision after the failed one"
desc="$(echo "$hist" | jq -r '.[-1].description')"
case "$desc" in
  Rollback*) hm_fail "The newest revision is a rollback ('$desc') — the 1.1 changes are not live" ;;
esac
echo "$hist" | jq -e 'map(select(.status=="failed"))|length>=1' >/dev/null \
  || hm_fail "The failed revision disappeared from the history"
[ "$(hm_release_chart ledger-sync)" = "ledger-sync-1.1.0" ] \
  || hm_fail "Release runs '$(hm_release_chart ledger-sync)', expected ledger-sync-1.1.0"

hm_info "Checking the 1.1 behaviour is live..."
env_json="$(kubectl get deployment ledger-sync -n "$NS" -o json 2>/dev/null | jq -c '.spec.template.spec.containers[0].env // []')"
echo "$env_json" | jq -e 'any(.[]; .name=="RECONCILE_MODE" and .value=="incremental")' >/dev/null \
  || hm_fail "RECONCILE_MODE is not 'incremental' on the live Deployment — the 1.1 changes are missing"
echo "$env_json" | jq -e 'any(.[]; .name=="BATCH_SIZE" and .value=="500")' >/dev/null \
  || hm_fail "BATCH_SIZE=500 is missing on the live Deployment"

hm_info "Checking the workload..."
hm_wait_rollout deployment/ledger-sync "$NS" 90s
ready="$(hm_jsonpath deployment/ledger-sync '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment ledger-sync has ${ready:-0}/2 ready pods"

hm_pass "ledger-sync 1.1 is live — you fixed forward."
