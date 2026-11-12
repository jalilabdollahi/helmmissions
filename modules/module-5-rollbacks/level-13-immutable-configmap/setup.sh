#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install flags "$LEVEL_DIR/assets/feature-flags" -n "$NS" --wait --timeout 90s >/dev/null
helm upgrade flags "$SANDBOX/feature-flags" -n "$NS" >"$HM_TMP/up.txt" 2>&1 && { echo "setup: upgrade unexpectedly succeeded"; exit 1; }
grep -q "immutable" "$HM_TMP/up.txt" || { cat "$HM_TMP/up.txt"; exit 1; }
hm_assert_status flags failed
