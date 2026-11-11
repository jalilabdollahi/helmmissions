#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=customer-notification-dispatcher-production-eu
hm_info "Checking the release..."
hm_require_deployed "$REL"

hm_info "Checking object names..."
names="$(hm_manifest_json "$REL" | jq -r '.[]|select(.kind=="Service")|.metadata.name')"
[ -n "$names" ] || hm_fail "The release has no Service"
while read -r n; do
  [ "${#n}" -le 63 ] || hm_fail "Service name '$n' has ${#n} characters (limit 63)"
done <<<"$names"
dep="$(hm_manifest_json "$REL" | jq -r '[.[]|select(.kind=="Deployment")][0].metadata.name // empty')"
[ -n "$dep" ] || hm_fail "The release has no Deployment"

hm_info "Checking the workload..."
hm_wait_rollout "deployment/$dep" "$NS" 90s
ready="$(hm_jsonpath "deployment/$dep" '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 1 ] || hm_fail "Deployment $dep has no ready pods"
first="$(echo "$names" | head -n1)"
[ "$(hm_endpoints_count "$first")" -ge 1 ] || hm_fail "Service $first has no ready endpoints"

hm_pass "The EU production release is live with names Kubernetes accepts."
