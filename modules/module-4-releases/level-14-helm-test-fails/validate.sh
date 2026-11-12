#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed rating-service
hm_wait_rollout deployment/rating-service "$NS" 90s

hm_info "Checking the test hook is still defined..."
helm get hooks rating-service -n "$NS" >"$HM_TMP/hooks.txt" 2>/dev/null
grep -q 'helm.sh/hook.*test' "$HM_TMP/hooks.txt" || hm_fail "The release has no test hook any more — the test was removed instead of fixed"
grep -q 'rating-service' "$HM_TMP/hooks.txt" || hm_fail "The test hook of the release does not target the rating-service Service"

hm_info "Running the release's test suite..."
helm test rating-service -n "$NS" --timeout 60s >"$HM_TMP/test.txt" 2>&1 \
  || hm_fail "helm test still fails for the deployed release" "$HM_TMP/test.txt"
hm_ok "helm test passed"

hm_pass "The smoke test is green."
