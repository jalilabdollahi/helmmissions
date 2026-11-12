#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_require_deployed mesh-client

hm_info "Checking the pod DNS configuration..."
s="$(kubectl get deploy mesh-client -n "$NS" -o json | jq -c '.spec.template.spec.dnsConfig.searches // null')"
[ "$s" != "null" ] || hm_fail "The Deployment has no dnsConfig.searches at all"
echo "$s" | jq -e 'type == "array"' >/dev/null || hm_fail "dnsConfig.searches is not a list: $s"
echo "$s" | jq -e 'sort == ["corp.internal","payments.svc.cluster.local"]' >/dev/null \
  || hm_fail "dnsConfig.searches is $s - expected the two domains payments.svc.cluster.local and corp.internal as separate entries"
hm_manifest_json mesh-client | jq -e '[.[] | select(.kind=="Deployment") | .spec.template.spec.dnsConfig.searches | length] | all(. == 2)' >/dev/null \
  || hm_fail "The release manifest does not carry the two search domains"

hm_wait_rollout deployment/mesh-client "$NS" 90s
ps="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=mesh-client -o json | jq -c '[.items[] | select(.metadata.deletionTimestamp==null) | .spec.dnsConfig.searches] | .[0]')"
echo "$ps" | jq -e 'sort == ["corp.internal","payments.svc.cluster.local"]' >/dev/null || hm_fail "The running pod does not have both search domains yet (got $ps)"
hm_pass "mesh-client resolves through both search domains."
