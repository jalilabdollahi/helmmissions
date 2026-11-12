#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm upgrade --install inventory "$SANDBOX/inventory-service" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: the chart installed — removed APIs are still served?"; exit 1
fi
grep -q 'no matches for kind "PodDisruptionBudget" in version "policy/v1beta1"' "$HM_TMP/install.txt" \
  || { cat "$HM_TMP/install.txt"; echo "setup: unexpected error text"; exit 1; }
