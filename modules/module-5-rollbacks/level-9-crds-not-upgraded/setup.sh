#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install snapshots "$LEVEL_DIR/assets/snapshot-scheduler" -n "$NS" --wait --timeout 90s >/dev/null
helm upgrade snapshots "$SANDBOX/snapshot-scheduler" -n "$NS" >"$HM_TMP/up.txt" 2>&1 && { echo "setup: upgrade unexpectedly succeeded"; exit 1; }
grep -q "retentionDays" "$HM_TMP/up.txt" || { cat "$HM_TMP/up.txt"; exit 1; }
hm_assert_status snapshots failed
