#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the Service..."
kubectl get service sms-gateway -n "$NS" >/dev/null 2>&1 || hm_fail "Service sms-gateway does not exist in namespace $NS"
owner="$(kubectl get service sms-gateway -n "$NS" -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}')"
[ "$owner" = "sms-gateway" ] || hm_fail "Service sms-gateway exists but is not owned by the Helm release (no Helm ownership metadata) - 'helm uninstall' would leave it behind"
[ "$(kubectl get service sms-gateway -n "$NS" -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}')" = "Helm" ] || hm_fail "Service sms-gateway is not labelled as managed by Helm"
hm_ok "Service sms-gateway is owned by the release"

hm_info "Checking the release..."
hm_require_deployed sms-gateway
[ "$(hm_release_revision sms-gateway)" -ge 3 ] || hm_fail "Helm has recorded no new revision since the Service was deleted"
hm_manifest_json sms-gateway | jq -e 'any(.[]; .kind=="Service" and .metadata.name=="sms-gateway")' >/dev/null || hm_fail "The release manifest no longer contains the Service"

hm_info "Checking traffic..."
hm_wait_rollout deployment/sms-gateway "$NS" 90s
[ "$(hm_endpoints_count sms-gateway)" -ge 1 ] || hm_fail "Service sms-gateway has no ready endpoints"
hm_http_check http://sms-gateway >"$HM_TMP/body.txt" || hm_fail "http://sms-gateway does not answer"

hm_pass "sms-gateway is reachable again and Helm owns its Service."
