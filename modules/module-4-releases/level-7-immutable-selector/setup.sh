#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install catalog-search "$LEVEL_DIR/assets/catalog-search" -n "$NS" --wait --timeout 90s >/dev/null
helm upgrade catalog-search "$SANDBOX/catalog-search" -n "$NS" --timeout 60s >"$HM_TMP/upgrade.txt" 2>&1 || true
[ "$(hm_release_status catalog-search)" = "failed" ] || { echo "setup: expected failed"; cat "$HM_TMP/upgrade.txt"; exit 1; }
grep -q "field is immutable" "$HM_TMP/upgrade.txt" || { cat "$HM_TMP/upgrade.txt"; exit 1; }
