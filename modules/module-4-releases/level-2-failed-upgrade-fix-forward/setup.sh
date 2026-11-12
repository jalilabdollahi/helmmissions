#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Revision 1: the healthy 1.0 release. Revision 2: the 1.1 chart from the workspace — rejected by the API.
helm install ledger-sync "$LEVEL_DIR/assets/ledger-sync" -n "$NS" --wait --timeout 90s >/dev/null
helm upgrade ledger-sync "$SANDBOX/ledger-sync" -n "$NS" --timeout 60s >"$HM_TMP/upgrade.txt" 2>&1 || true
[ "$(hm_release_status ledger-sync)" = "failed" ] || { echo "setup: expected failed"; cat "$HM_TMP/upgrade.txt"; exit 1; }
[ "$(hm_release_revision ledger-sync)" = "2" ] || { echo "setup: expected revision 2"; exit 1; }
grep -q "handler type" "$HM_TMP/upgrade.txt" || { cat "$HM_TMP/upgrade.txt"; exit 1; }
