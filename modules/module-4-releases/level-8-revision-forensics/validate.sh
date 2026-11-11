#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release history..."
hm_require_deployed product-search
hist="$(hm_history_json product-search)"
latest="$(echo "$hist" | jq -r '.[-1].revision')"
[ "$latest" -ge 6 ] || hm_fail "Release is still on revision $latest — nothing new was deployed"
case "$(echo "$hist" | jq -r '.[-1].description')" in
  Rollback*) hm_fail "The newest revision is a rollback — the changes from revisions 4 and 5 would be lost" ;;
esac

hm_info "Checking the settings in the release manifest and in the cluster..."
cm="$(hm_manifest_json product-search | jq -c '[.[]|select(.kind=="ConfigMap")][0].data // {}')"
live="$(kubectl get configmap product-search-config -n "$NS" -o json 2>/dev/null | jq -c '.data // {}')"
for src in "$cm" "$live"; do
  [ "$(echo "$src" | jq -r .FEATURE_SEARCH)" = "true" ] || hm_fail "FEATURE_SEARCH is not true — search is still switched off"
  [ "$(echo "$src" | jq -r .CACHE_TTL_SECONDS)" = "600" ] || hm_fail "CACHE_TTL_SECONDS is '$(echo "$src" | jq -r .CACHE_TTL_SECONDS)' — the change from revision 4 was lost"
  [ "$(echo "$src" | jq -r .LOG_LEVEL)" = "warn" ] || hm_fail "LOG_LEVEL is '$(echo "$src" | jq -r .LOG_LEVEL)' — the change from revision 5 was lost"
  [ "$(echo "$src" | jq -r .FEATURE_RECOMMEND)" = "false" ] || hm_fail "FEATURE_RECOMMEND was switched back on — only search should change"
done

hm_info "Checking the workload..."
hm_wait_rollout deployment/product-search "$NS" 90s
[ "$(hm_jsonpath deployment/product-search '{.spec.replicas}')" = "2" ] || hm_fail "Deployment product-search is not running 2 replicas (revision 2's change was lost)"
ready="$(hm_jsonpath deployment/product-search '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment product-search has ${ready:-0}/2 ready pods"

hm_pass "Search is back and nobody's other changes were thrown away."
