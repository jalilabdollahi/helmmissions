#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# First install: the subchart's pre-install hook fails, so the release is recorded as failed.
helm dependency update "$SANDBOX/checkout" >/dev/null 2>&1
if helm install checkout "$SANDBOX/checkout" -n "$NS" --wait --timeout 120s >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: install succeeded — scenario is not broken"; exit 1
fi
grep -q "failed pre-install" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
hm_assert_status checkout failed
kubectl get job checkout-schema-migrator-migrate -n "$NS" >/dev/null 2>&1 || { echo "setup: hook Job missing"; exit 1; }
