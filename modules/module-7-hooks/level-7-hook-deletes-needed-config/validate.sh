#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed gateway
hm_wait_rollout deployment/gateway "$NS" 90s

hm_info "Checking who owns the routing table..."
hm_manifest_json gateway | jq -e '[.[] | select(.kind=="ConfigMap" and .metadata.name=="gateway-routes")] | length == 1' >/dev/null \
  || hm_fail "ConfigMap gateway-routes is not part of the release manifest — Helm does not manage it like a normal resource"
kubectl get configmap gateway-routes -n "$NS" >/dev/null 2>&1 || hm_fail "ConfigMap gateway-routes does not exist in the cluster"
helm get hooks gateway -n "$NS" 2>/dev/null | grep -q 'gateway-routes' && hm_fail "ConfigMap gateway-routes is still a hook resource of the release"
hm_ok "The ConfigMap belongs to the release"

hm_info "Checking the gateway serves the routing table..."
body="$(hm_http_check http://gateway.$NS.svc.cluster.local/ "$NS" 5)" || hm_fail "The gateway does not answer on its Service"
echo "$body" | grep -q '^gateway routes v3' || hm_fail "The gateway answers, but not with the v3 routing table: $body"
hm_ok "Gateway answers: $body"

hm_pass "The routing table is part of the release and the gateway serves it."
