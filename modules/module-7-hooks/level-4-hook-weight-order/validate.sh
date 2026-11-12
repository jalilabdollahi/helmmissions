#!/bin/bash
set -uo pipefail
source "$HM_LIB"
V=helmissions-verify
trap 'helm uninstall ord-verify -n "$V" >/dev/null 2>&1 || true; kubectl delete ns "$V" --wait=false >/dev/null 2>&1 || true; rm -rf "$HM_TMP"' EXIT

# state_ok NAMESPACE → both hooks left their evidence, init strictly before (or at the same second as) migrate
state_ok() {
  local cm; cm="$(kubectl get configmap orders-schema-state -n "$1" -o json 2>/dev/null)" || return 1
  local i m
  i="$(echo "$cm" | jq -r '.data["initialized-at"] // empty')"
  m="$(echo "$cm" | jq -r '.data["migrated-at"] // empty')"
  [ -n "$i" ] && [ -n "$m" ] && [[ ! "$m" < "$i" ]]
}

hm_info "Checking the live release..."
hm_require_deployed orders
hm_wait_rollout deployment/orders "$NS" 90s
for j in orders-db-init orders-db-migrate; do
  [ "$(kubectl get job "$j" -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null)" = "1" ] \
    || hm_fail "Hook Job $j has not completed successfully in the live release"
done
state_ok "$NS" || hm_fail "The database state shows the migration did not run after the schema initialisation"
hm_ok "Both database hooks ran, init before migrate"

hm_info "Installing the chart into an empty namespace to prove the ordering..."
kubectl delete ns "$V" --wait=true --timeout=90s >/dev/null 2>&1 || true
kubectl create ns "$V" >/dev/null 2>&1 || hm_fail "Cannot create verification namespace"
helm install ord-verify "$SANDBOX/order-service" -n "$V" --timeout 90s >"$HM_TMP/i.txt" 2>&1 \
  || hm_fail "A fresh install of the chart still fails" "$HM_TMP/i.txt"
state_ok "$V" || hm_fail "On a fresh install the migration did not run after the schema initialisation"
hm_ok "Fresh install: schema initialised first, migrations second"

hm_pass "The database is prepared in the right order."
