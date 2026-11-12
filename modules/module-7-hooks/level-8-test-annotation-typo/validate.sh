#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed search
hm_wait_rollout deployment/search "$NS" 90s

hm_info "Checking the release really contains a test hook..."
helm get hooks search -n "$NS" >"$HM_TMP/hooks.txt" 2>/dev/null
grep -Eq '"?helm.sh/hook"?: *"?test(-success)?"?[[:space:]]*$' "$HM_TMP/hooks.txt" \
  || hm_fail "The release has no test hook: helm test has nothing to run (hooks are read from the stored release, not from your files)"
grep -q 'search' "$HM_TMP/hooks.txt" || hm_fail "The test hook does not exercise the search endpoint"

hm_info "Running helm test..."
helm test search -n "$NS" --timeout 60s >"$HM_TMP/test.txt" 2>&1 \
  || hm_fail "helm test fails" "$HM_TMP/test.txt"
grep -q 'Phase: *Succeeded' "$HM_TMP/test.txt" || hm_fail "helm test ran no test pod that succeeded" "$HM_TMP/test.txt"
pod="$(kubectl get pods -n "$NS" -l app.kubernetes.io/component=test -o name 2>/dev/null | head -1)"
[ -n "$pod" ] || hm_fail "No test pod was created by helm test"
kubectl logs "$pod" -n "$NS" 2>/dev/null | grep -q 'hits' || hm_fail "The test pod did not query the search endpoint"
hm_ok "helm test ran the search test and it passed"

hm_pass "The test suite is real and green."
