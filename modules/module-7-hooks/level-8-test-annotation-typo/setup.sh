#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install search "$SANDBOX/inventory-search" -n "$NS" --wait --timeout 90s >/dev/null
hm_assert_status search deployed
helm test search -n "$NS" --timeout 30s >"$HM_TMP/test.txt" 2>&1 || { cat "$HM_TMP/test.txt"; echo "setup: helm test errored (expected a silent no-op)"; exit 1; }
grep -q 'TEST SUITE: *None' "$HM_TMP/test.txt" || { cat "$HM_TMP/test.txt"; echo "setup: helm test did not report 'TEST SUITE: None'"; exit 1; }
[ -z "$(helm get hooks search -n "$NS" | grep -v '^---' | tr -d '[:space:]')" ] || { echo "setup: release unexpectedly has hooks"; exit 1; }
