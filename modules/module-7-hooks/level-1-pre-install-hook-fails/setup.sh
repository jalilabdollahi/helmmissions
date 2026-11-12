#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# First deploy: the pre-install migration hook fails, so the release ends up failed.
helm install ledger-api "$SANDBOX/ledger-api" -n "$NS" --timeout 90s >"$HM_TMP/install.txt" 2>&1 && { echo "setup: install succeeded — scenario not broken"; exit 1; }
hm_assert_status ledger-api failed
grep -q "pre-install" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; echo "setup: install did not fail in the pre-install phase"; exit 1; }
[ "$(kubectl get job ledger-api-migrate -n "$NS" -o jsonpath='{.status.failed}' 2>/dev/null)" = "1" ] || { echo "setup: migration job did not fail"; exit 1; }
