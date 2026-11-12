#!/bin/bash
set -uo pipefail
source "$HM_LIB"

TARGET="helmissions-staging"

hm_info "Checking where the release landed..."
if hm_release_exists metrics-proxy "$NS"; then
  hm_fail "Release metrics-proxy was installed in '$NS' - the ticket asks for namespace '$TARGET'"
fi
kubectl get namespace "$TARGET" >/dev/null 2>&1 || hm_fail "Namespace '$TARGET' does not exist"
hm_require_deployed metrics-proxy "$TARGET"
chart="$(hm_release_chart metrics-proxy "$TARGET")"
[ "$chart" = "metrics-proxy-0.9.0" ] || hm_fail "Release metrics-proxy runs chart '$chart', expected the chart from the workspace"

hm_info "Checking the workload in $TARGET..."
hm_wait_rollout deployment/metrics-proxy "$TARGET" 90s
[ "$(hm_endpoints_count metrics-proxy "$TARGET")" -ge 1 ] || hm_fail "Service metrics-proxy has no ready endpoints in $TARGET"
n="$(kubectl get deploy -n "$NS" -o name 2>/dev/null | grep -c metrics-proxy || true)"
[ "$n" = 0 ] || hm_fail "A stray metrics-proxy Deployment exists in '$NS'"

hm_pass "metrics-proxy is running in $TARGET."
