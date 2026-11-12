#!/bin/bash
set -uo pipefail
source "$HM_LIB"

# The pipeline's release lives in ConfigMaps, so read it the way the pipeline does.
export HELM_DRIVER=configmap

hm_info "Looking for the pipeline's release..."
hist="$(helm history audit-gateway -n "$NS" -o json 2>/dev/null || echo '[]')"
[ "$(echo "$hist" | jq length)" -ge 2 ] || hm_fail "Cannot find the audit-gateway release the pipeline manages (the one with 2+ revisions)"
st="$(helm status audit-gateway -n "$NS" -o json | jq -r '.info.status')"
[ "$st" = "deployed" ] || hm_fail "The pipeline's release is '$st', expected 'deployed'"
desc="$(echo "$hist" | jq -r '.[-1].description')"
[ "$desc" = "Rollback to 1" ] || hm_fail "The pipeline's release has not been rolled back: newest revision says '$desc'"
hm_ok "The pipeline's release was rolled back to revision 1"

hm_info "Checking the workload..."
args="$(hm_jsonpath deployment/audit-gateway '{.spec.template.spec.containers[0].args}')"
[ -z "$args" ] || hm_fail "The Deployment still passes arguments to the gateway: $args"
hm_wait_rollout deployment/audit-gateway "$NS" 90s
[ "$(hm_endpoints_count audit-gateway)" -ge 1 ] || hm_fail "Service audit-gateway has no ready endpoints"

unset HELM_DRIVER
hm_info "Checking that no second release was created..."
[ -z "$(helm list -n "$NS" -q 2>/dev/null)" ] || hm_fail "A second release exists in the default (Secret) storage: $(helm list -n "$NS" -q | tr '\n' ' ')"

hm_pass "audit-gateway is back on revision 1, in the release the pipeline owns."
