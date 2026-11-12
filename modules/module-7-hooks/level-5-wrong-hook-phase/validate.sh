#!/bin/bash
set -uo pipefail
source "$HM_LIB"
V=helmissions-verify
trap 'helm uninstall ship-verify -n "$V" >/dev/null 2>&1 || true; kubectl delete ns "$V" --wait=false >/dev/null 2>&1 || true; rm -rf "$HM_TMP"' EXIT

hm_info "Checking the live release..."
hm_require_deployed shipments
[ "$(hm_release_chart shipments)" = "shipment-tracker-1.1.0" ] || hm_fail "Release runs '$(hm_release_chart shipments)', expected shipment-tracker-1.1.0"
hm_wait_rollout deployment/shipments "$NS" 90s
kubectl get pods -n "$NS" -l app.kubernetes.io/name=shipment-tracker -o json \
  | jq -e '[.items[] | select(.metadata.deletionTimestamp==null) | select(.spec.initContainers!=null)] | length > 0' >/dev/null \
  || hm_fail "No pod of the 1.1 version (with the schema check) is running"
[ "$(kubectl get job shipments-migrate-v2 -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null)" = "1" ] \
  || hm_fail "The schema migration Job shipments-migrate-v2 never completed as part of a deploy"
hm_ok "1.1 is running and the migration completed"

hm_info "Replaying the deploy on a fresh release (1.0.0 -> workspace chart)..."
kubectl delete ns "$V" --wait=true --timeout=90s >/dev/null 2>&1 || true
kubectl create ns "$V" >/dev/null 2>&1 || hm_fail "Cannot create verification namespace"
helm install ship-verify "$LEVEL_DIR/assets/v1/shipment-tracker" -n "$V" --wait --timeout 90s >"$HM_TMP/i.txt" 2>&1 || hm_fail "Could not install the 1.0.0 baseline for verification" "$HM_TMP/i.txt"
helm upgrade ship-verify "$SANDBOX/shipment-tracker" -n "$V" --wait --timeout 90s >"$HM_TMP/u.txt" 2>&1 \
  || hm_fail "Upgrading a fresh 1.0.0 release to the workspace chart with --wait still fails" "$HM_TMP/u.txt"
hm_ok "A fresh 1.0.0 -> 1.1.0 upgrade with --wait succeeds"

hm_pass "The schema is migrated before the new pods need it."
