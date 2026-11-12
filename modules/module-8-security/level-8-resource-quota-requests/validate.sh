#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=search-indexer
hm_info "Checking the quota is untouched..."
q="$(kubectl get resourcequota search-team-quota -n "$NS" -o json 2>/dev/null || true)"
[ -n "$q" ] || hm_fail "ResourceQuota search-team-quota is gone — the platform policy was removed"
echo "$q" | jq -e '.spec.hard == {"pods":"4","requests.cpu":"200m","requests.memory":"256Mi","limits.cpu":"400m","limits.memory":"512Mi"}' >/dev/null \
  || hm_fail "ResourceQuota search-team-quota no longer has its original limits"
hm_ok "Quota is intact"

hm_require_deployed "$REL"
hm_info "Checking the resources declared by the release..."
manifest="$(hm_manifest_json "$REL")"
echo "$manifest" | jq -e '[.[]|select(.kind=="Deployment")|.spec.template.spec.containers[]
  | select((.resources.requests.cpu//"")=="" or (.resources.requests.memory//"")=="" or (.resources.limits.cpu//"")=="" or (.resources.limits.memory//"")=="")]|length==0' >/dev/null \
  || hm_fail "A container in the release still lacks cpu/memory requests or limits"
hm_ok "Every container declares requests and limits"

hm_info "Checking the workload..."
hm_wait_rollout "deployment/$REL" "$NS" 45s
ready="$(hm_jsonpath "deployment/$REL" '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment $REL has ${ready:-0}/2 ready pods"
[ "$(hm_jsonpath "deployment/$REL" '{.spec.replicas}')" -ge 2 ] || hm_fail "The Deployment was scaled below 2 replicas"
hm_pass "The indexer runs inside the quota — and the quota is still in force."
