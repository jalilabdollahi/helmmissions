#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install catalog "$LEVEL_DIR/assets/catalog-seed" -n "$NS" --wait --timeout 90s >/dev/null
kubectl wait --for=condition=complete job/catalog-seed -n "$NS" --timeout=60s >/dev/null
helm upgrade catalog "$SANDBOX/catalog-seed" -n "$NS" >"$HM_TMP/up.txt" 2>&1 && { echo "setup: upgrade unexpectedly succeeded"; exit 1; }
grep -q "field is immutable" "$HM_TMP/up.txt" || { cat "$HM_TMP/up.txt"; exit 1; }
hm_assert_status catalog failed
