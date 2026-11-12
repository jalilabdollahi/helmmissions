#!/bin/bash
set -uo pipefail
source "$HM_LIB"
V=helmissions-verify
trap 'kubectl delete ns "$V" --wait=false >/dev/null 2>&1 || true; rm -rf "$HM_TMP"' EXIT

hm_info "Checking the live release..."
hm_require_deployed payments-gateway
hm_wait_rollout deployment/payments-gateway "$NS" 90s
helm get hooks payments-gateway -n "$NS" >"$HM_TMP/hooks.txt" 2>/dev/null
grep -Eq 'helm.sh/hook.*post-(install|upgrade)' "$HM_TMP/hooks.txt" && grep -q 'kind: Job' "$HM_TMP/hooks.txt" \
  || hm_fail "The release has no post-deploy smoke test hook any more — the test was removed instead of fixed"
[ "$(kubectl get job payments-gateway-smoke -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null)" = "1" ] \
  || hm_fail "The smoke test Job payments-gateway-smoke has not completed successfully in the live release"
pod="$(kubectl get pods -n "$NS" -l job-name=payments-gateway-smoke --field-selector=status.phase=Succeeded -o name 2>/dev/null | head -1)"
kubectl logs "$pod" -n "$NS" >"$HM_TMP/smoke.txt" 2>&1
grep -q 'Hostname' "$HM_TMP/smoke.txt" \
  || hm_fail "The smoke test passed without ever getting an answer from the gateway" "$HM_TMP/smoke.txt"
hm_ok "Live smoke test completed against the gateway"

hm_info "Proving the pipeline works on a brand-new environment (can take a minute)..."
kubectl delete ns "$V" --wait=true --timeout=90s >/dev/null 2>&1 || true
NAMESPACE="$V" RELEASE=pg-verify bash "$SANDBOX/ci/deploy.sh" >"$HM_TMP/fresh.txt" 2>&1 \
  || hm_fail "ci/deploy.sh fails on a fresh environment" "$HM_TMP/fresh.txt"
[ "$(hm_release_status pg-verify "$V")" = "deployed" ] || hm_fail "Fresh environment release is not deployed"
[ "$(kubectl get job pg-verify-smoke -n "$V" -o jsonpath='{.status.succeeded}' 2>/dev/null)" = "1" ] \
  || hm_fail "On a fresh environment the smoke test hook did not run to success (it was skipped or is still failing)"
hm_ok "Fresh environment deploys with a passing smoke test"

hm_pass "The smoke test now waits for the gateway instead of racing it."
