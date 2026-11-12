#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed settlement-batch
hist="$(hm_history_json settlement-batch)"
[ "$(echo "$hist" | jq -r '.[-1].status')" = "deployed" ] || hm_fail "The newest revision is '$(echo "$hist" | jq -r '.[-1].status')' - the release is not in a clean state"
mimg="$(hm_manifest_json settlement-batch | jq -r '[.[]|select(.kind=="Deployment")][0].spec.template.spec.containers[0].image')"
[ "$mimg" = "traefik/whoami:v1.10" ] || hm_fail "The release's current manifest still deploys image '$mimg'"

hm_info "Checking the workload..."
img="$(hm_jsonpath deployment/settlement-batch '{.spec.template.spec.containers[0].image}')"
[ "$img" = "traefik/whoami:v1.10" ] || hm_fail "Deployment settlement-batch runs '$img'"
hm_wait_rollout deployment/settlement-batch "$NS" 90s
[ "$(hm_endpoints_count settlement-batch)" -ge 1 ] || hm_fail "Service settlement-batch has no ready endpoints"

hm_pass "settlement-batch is healthy again."
