#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install docs-portal "$LEVEL_DIR/assets/docs-portal" -n "$NS" --wait --timeout 90s >/dev/null
# The CI job: 2.1 with --wait. The new pods never turn Ready, so Helm gives up.
helm upgrade docs-portal "$SANDBOX/docs-portal" -n "$NS" --wait --timeout 30s >"$HM_TMP/upgrade.txt" 2>&1 || true
[ "$(hm_release_status docs-portal)" = "failed" ] || { echo "setup: expected failed"; cat "$HM_TMP/upgrade.txt"; exit 1; }
[ "$(hm_release_revision docs-portal)" = "2" ] || { echo "setup: expected revision 2"; exit 1; }
grep -q "deadline exceeded\|timed out" "$HM_TMP/upgrade.txt" || { cat "$HM_TMP/upgrade.txt"; exit 1; }
