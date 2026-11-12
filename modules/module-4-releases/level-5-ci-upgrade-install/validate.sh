#!/bin/bash
set -uo pipefail
source "$HM_LIB"

[ -f "$SANDBOX/ci/deploy.sh" ] || hm_fail "ci/deploy.sh is missing from the workspace"

hm_info "Checking the deployment in $NS..."
hm_require_deployed shipment-tracker
hm_wait_rollout deployment/shipment-tracker "$NS" 90s

# The fix must live in the pipeline script: prove it on an environment that has never seen the release.
hm_info "Replaying the script against a brand-new environment (helmissions-ci)..."
kubectl delete namespace helmissions-ci --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create namespace helmissions-ci >/dev/null 2>&1 || hm_fail "Could not create the verification namespace"
for run in 1 2; do
  (cd "$SANDBOX" && NAMESPACE=helmissions-ci bash ci/deploy.sh) >"$HM_TMP/ci-$run.txt" 2>&1 \
    || { kubectl delete namespace helmissions-ci --wait=false >/dev/null 2>&1; hm_fail "ci/deploy.sh fails against a fresh environment (run $run)" "$HM_TMP/ci-$run.txt"; }
done
st="$(hm_release_status shipment-tracker helmissions-ci)"
kubectl delete namespace helmissions-ci --wait=false >/dev/null 2>&1
[ "$st" = "deployed" ] || hm_fail "After running the script in a fresh namespace the release is '${st:-missing}', expected deployed"
hm_ok "The script works on a first deploy and when repeated"

hm_pass "ci/deploy.sh is idempotent — new environments no longer break the pipeline."
