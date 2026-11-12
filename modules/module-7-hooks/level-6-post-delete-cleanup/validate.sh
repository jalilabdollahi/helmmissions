#!/bin/bash
set -uo pipefail
source "$HM_LIB"
V=helmissions-verify
trap 'helm uninstall exp-verify -n "$V" >/dev/null 2>&1 || true; kubectl delete ns "$V" --wait=false >/dev/null 2>&1 || true; rm -rf "$HM_TMP"' EXIT

hm_info "Checking for volumes left behind in $NS..."
kubectl get pvc exports-scratch -n "$NS" >/dev/null 2>&1 && hm_fail "PVC exports-scratch from the earlier uninstall is still in namespace $NS"
hm_ok "No stale scratch volume"

hm_info "Running a full install/uninstall cycle in a throwaway namespace..."
kubectl delete ns "$V" --wait=true --timeout=90s >/dev/null 2>&1 || true
kubectl create ns "$V" >/dev/null 2>&1 || hm_fail "Cannot create verification namespace"
# no --wait: a PVC owned by the chart stays Pending without a consumer (WaitForFirstConsumer)
helm install exp-verify "$SANDBOX/export-batch" -n "$V" --timeout 90s >"$HM_TMP/i.txt" 2>&1 \
  || hm_fail "A fresh install of the chart fails" "$HM_TMP/i.txt"
kubectl get pvc exp-verify-scratch -n "$V" >/dev/null 2>&1 \
  || hm_fail "The install no longer creates the scratch volume (PVC exp-verify-scratch)"
hm_ok "Install creates the scratch volume"
helm uninstall exp-verify -n "$V" --timeout 90s >"$HM_TMP/u.txt" 2>&1 \
  || hm_fail "helm uninstall failed" "$HM_TMP/u.txt"
for _ in $(seq 1 20); do
  [ -z "$(kubectl get pvc -n "$V" -o name 2>/dev/null)" ] && break
  sleep 2
done
left="$(kubectl get pvc -n "$V" -o name 2>/dev/null)"
[ -z "$left" ] || hm_fail "After helm uninstall these PVCs are still there: $(echo $left)"
hm_ok "Uninstall leaves no PVC behind"

hm_pass "Uninstall cleans up after itself."
