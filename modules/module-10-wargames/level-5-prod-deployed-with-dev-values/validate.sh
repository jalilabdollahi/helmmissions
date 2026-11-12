#!/bin/bash
set -uo pipefail
source "$HM_LIB"

[ -f "$SANDBOX/deploy.sh" ] || hm_fail "deploy.sh is missing from the workspace"
hm_info "Running the prod pipeline from the workspace..."
bash "$SANDBOX/deploy.sh" prod >"$HM_TMP/deploy1.txt" 2>&1 || hm_fail "deploy.sh prod failed" "$HM_TMP/deploy1.txt"
hm_ok "deploy.sh prod succeeded"

hm_require_deployed invoice
hm_wait_rollout deployment/invoice "$NS" 90s
for _ in $(seq 1 20); do
  total="$(kubectl get pods -n "$NS" -l app.kubernetes.io/instance=invoice --no-headers | wc -l | tr -d ' ')"
  [ "$total" = "2" ] && break
  sleep 2
done
ready="$(hm_pods_json app.kubernetes.io/instance=invoice | jq '[.[]|select(.status.containerStatuses[0].ready==true)]|length')"
[ "$ready" = "2" ] || hm_fail "Prod has $ready ready pods, expected 2"

hm_info "Checking the prod configuration page..."
for _ in 1 2 3 4; do
  hm_http_check http://invoice/config.txt >"$HM_TMP/prod.txt" 2>/dev/null
  grep -q "environment=prod" "$HM_TMP/prod.txt" && break
  sleep 3
done
for want in "environment=prod" "payments=live" "log_level=warn" "debug_endpoints=false" "database=invoice-db.helmissions"; do
  grep -qx "$want" "$HM_TMP/prod.txt" || hm_fail "Prod configuration page does not say '$want'" "$HM_TMP/prod.txt"
done
hm_ok "Prod runs the production configuration"

hm_info "Checking the pipeline is idempotent and leaves prod alone on a re-run..."
bash "$SANDBOX/deploy.sh" prod >"$HM_TMP/deploy2.txt" 2>&1 || hm_fail "A second deploy.sh prod run failed" "$HM_TMP/deploy2.txt"
hm_http_check http://invoice/config.txt >"$HM_TMP/prod2.txt" 2>/dev/null
grep -qx "payments=live" "$HM_TMP/prod2.txt" && grep -qx "debug_endpoints=false" "$HM_TMP/prod2.txt" || hm_fail "A second pipeline run changed the production configuration" "$HM_TMP/prod2.txt"

hm_info "Checking dev is untouched..."
hm_require_deployed invoice-dev helmissions-dev
hm_http_check http://invoice-dev/config.txt helmissions-dev >"$HM_TMP/dev.txt" 2>/dev/null || hm_fail "Dev config page does not answer"
for want in "environment=dev" "payments=sandbox" "log_level=debug" "debug_endpoints=true" "database=invoice-db.helmissions-dev"; do
  grep -qx "$want" "$HM_TMP/dev.txt" || hm_fail "Dev configuration page does not say '$want' any more" "$HM_TMP/dev.txt"
done
hm_pass "Prod is production again, and the pipeline keeps it that way."
