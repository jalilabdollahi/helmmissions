#!/bin/bash
set -uo pipefail
source "$HM_LIB"
V=helmissions-verify
trap 'helm uninstall tx-verify -n "$V" >/dev/null 2>&1 || true; kubectl delete ns "$V" --wait=false >/dev/null 2>&1 || true; rm -rf "$HM_TMP"' EXIT

hm_info "Checking the live release..."
hm_require_deployed tax-engine
hm_wait_rollout deployment/tax-engine "$NS" 90s
desc="$(hm_release_description tax-engine)"
[ "$desc" = "Upgrade complete" ] || hm_fail "The newest revision is '$desc', expected a successful upgrade"

hm_info "Checking the rate check is still a hook..."
helm get hooks tax-engine -n "$NS" >"$HM_TMP/hooks.txt" 2>/dev/null
grep -q 'kind: Job' "$HM_TMP/hooks.txt" && grep -Eq 'helm.sh/hook.*pre-upgrade' "$HM_TMP/hooks.txt" \
  || hm_fail "The release has no pre-upgrade rate-check hook any more — it was removed instead of fixed"
# the Job may already be cleaned up by its delete policy; if it is still there it must have succeeded
if kubectl get job tax-engine-rate-check -n "$NS" >/dev/null 2>&1; then
  [ "$(kubectl get job tax-engine-rate-check -n "$NS" -o jsonpath='{.status.succeeded}')" = "1" ] \
    || hm_fail "The rate-check Job did not complete in the live release"
fi

hm_info "Upgrading a fresh release repeatedly (the second deploy is the one that used to break)..."
kubectl delete ns "$V" --wait=true --timeout=90s >/dev/null 2>&1 || true
kubectl create ns "$V" >/dev/null 2>&1 || hm_fail "Cannot create verification namespace"
helm install tx-verify "$SANDBOX/tax-engine" -n "$V" --timeout 90s >"$HM_TMP/i.txt" 2>&1 || hm_fail "A fresh install of the chart fails" "$HM_TMP/i.txt"
for n in 2 3; do
  helm upgrade tx-verify "$SANDBOX/tax-engine" -n "$V" --timeout 90s >"$HM_TMP/u.txt" 2>&1 \
    || hm_fail "Upgrade #$n of the chart still collides with the hook Job left by the previous deploy" "$HM_TMP/u.txt"
done
if kubectl get job tx-verify-rate-check -n "$V" >/dev/null 2>&1; then   # may already be cleaned up by the delete policy
  [ "$(kubectl get job tx-verify-rate-check -n "$V" -o jsonpath='{.status.succeeded}')" = "1" ] \
    || hm_fail "The rate check did not run to success on the repeated upgrades"
fi
hm_ok "Three deploys in a row, the hook ran every time"

hm_pass "Hook Jobs no longer pile up between deploys."
