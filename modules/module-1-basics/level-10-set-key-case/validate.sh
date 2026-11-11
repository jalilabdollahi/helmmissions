#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release values..."
hm_require_deployed billing
uv="$(hm_user_values billing)"
rc="$(echo "$uv" | jq -r '.replicaCount // empty')"
[ "$rc" = "4" ] || hm_fail "The release's user-supplied replicaCount is '${rc:-unset}', expected 4"
echo "$uv" | jq -e 'has("replicacount") | not' >/dev/null \
  || hm_fail "The release still carries the stray key 'replicacount' in its user-supplied values (helm get values billing)"
hm_ok "Release values contain replicaCount: 4 and nothing stray"

hm_info "Checking the workload..."
spec="$(hm_jsonpath deployment/billing '{.spec.replicas}')"
[ "$spec" = "4" ] || hm_fail "Deployment billing has $spec replica(s), expected 4"
hm_wait_rollout deployment/billing "$NS" 90s
ready="$(hm_jsonpath deployment/billing '{.status.readyReplicas}')"
[ "${ready:-0}" = "4" ] || hm_fail "Deployment billing has ${ready:-0}/4 ready pods"

hm_pass "billing runs 4 workers, set through the right key."
