#!/bin/bash
set -uo pipefail
source "$HM_LIB"
V=helmissions-verify
trap 'helm uninstall ten-verify -n "$V" >/dev/null 2>&1 || true; kubectl delete ns "$V" --wait=false >/dev/null 2>&1 || true; rm -rf "$HM_TMP"' EXIT

hm_info "Checking the live release..."
hm_require_deployed tenants
hm_wait_rollout deployment/tenants "$NS" 90s
helm get hooks tenants -n "$NS" >"$HM_TMP/hooks.txt" 2>/dev/null
grep -q 'tenants-preflight' "$HM_TMP/hooks.txt" || hm_fail "The preflight hook is no longer part of the release — it must still run before the install"
[ "$(kubectl get job tenants-preflight -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null)" = "1" ] \
  || hm_fail "The preflight Job has not completed successfully in the live release"
kubectl logs job/tenants-preflight -n "$NS" 2>/dev/null | grep -q 'no maintenance window active' \
  || hm_fail "The preflight Job finished without actually checking for maintenance windows"
hm_ok "Preflight ran and passed"

hm_info "Installing into an empty namespace (RBAC must come from the chart)..."
kubectl delete ns "$V" --wait=true --timeout=90s >/dev/null 2>&1 || true
kubectl create ns "$V" >/dev/null 2>&1 || hm_fail "Cannot create verification namespace"
helm install ten-verify "$SANDBOX/tenant-onboarding" -n "$V" --timeout 90s >"$HM_TMP/i.txt" 2>&1 \
  || hm_fail "A fresh install of the chart still fails in the preflight hook" "$HM_TMP/i.txt"
[ "$(hm_release_status ten-verify "$V")" = "deployed" ] || hm_fail "Fresh install is not deployed"
hm_ok "Fresh install passes the preflight check"

hm_pass "The hook has the permissions it needs, from the chart itself."
