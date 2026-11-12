#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the release..."
hm_require_deployed ledger-api
hm_wait_rollout deployment/ledger-api "$NS" 90s

hm_info "Checking the migration hook is still part of the release..."
helm get hooks ledger-api -n "$NS" >"$HM_TMP/hooks.txt" 2>/dev/null
grep -q 'ledger-api-migrate' "$HM_TMP/hooks.txt" && grep -Eq 'helm.sh/hook.*pre-(install|upgrade)' "$HM_TMP/hooks.txt" \
  || hm_fail "The release has no pre-install migration hook any more — the migration must still run before the API starts"

hm_info "Checking the migration really ran..."
ok="$(kubectl get job ledger-api-migrate -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null || true)"
[ "$ok" = "1" ] || hm_fail "Job ledger-api-migrate has not completed successfully (the migration never ran to the end)"
kubectl logs job/ledger-api-migrate -n "$NS" >"$HM_TMP/logs.txt" 2>&1
grep -q '3 migrations applied' "$HM_TMP/logs.txt" || hm_fail "The migration Job finished but did not apply the ledger migrations" "$HM_TMP/logs.txt"
hm_ok "Migration Job completed: 3 migrations applied"

hm_pass "The migration ran and ledger-api is deployed."
