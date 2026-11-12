#!/bin/bash
set -uo pipefail
source "$HM_LIB"
V=helmissions-verify
trap 'helm uninstall pay-verify -n "$V" >/dev/null 2>&1 || true; kubectl delete ns "$V" --wait=false >/dev/null 2>&1 || true; rm -rf "$HM_TMP"' EXIT

hm_info "Checking the live release..."
hm_require_deployed payroll
hm_wait_rollout deployment/payroll "$NS" 90s
kubectl get secret payroll-db -n "$NS" >/dev/null 2>&1 || hm_fail "Secret payroll-db does not exist — the application pod cannot use it"
[ "$(kubectl get job payroll-db-bootstrap -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null)" = "1" ] \
  || hm_fail "The bootstrap Job payroll-db-bootstrap has not completed successfully (it was skipped or is still failing)"
kubectl logs job/payroll-db-bootstrap -n "$NS" 2>/dev/null | grep -q 'role payroll_app created' \
  || hm_fail "The bootstrap Job did not create the database role"
helm get hooks payroll -n "$NS" 2>/dev/null | grep -q 'payroll-db-bootstrap' || hm_fail "The bootstrap is no longer a hook of the release"
hm_ok "Bootstrap ran with the Secret and the application is up"

hm_info "Installing into an empty namespace..."
kubectl delete ns "$V" --wait=true --timeout=90s >/dev/null 2>&1 || true
kubectl create ns "$V" >/dev/null 2>&1 || hm_fail "Cannot create verification namespace"
helm install pay-verify "$SANDBOX/payroll-api" -n "$V" --wait --timeout 90s >"$HM_TMP/i.txt" 2>&1 \
  || hm_fail "A fresh install of the chart still fails" "$HM_TMP/i.txt"
kubectl get secret pay-verify-db -n "$V" >/dev/null 2>&1 || hm_fail "On a fresh install the Secret is gone after the deploy"
hm_ok "Fresh install works and the Secret survives"

hm_pass "The Secret exists before the hook needs it and stays for the app."
