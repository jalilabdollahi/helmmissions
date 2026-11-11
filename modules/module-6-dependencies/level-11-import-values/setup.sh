#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The chart is packaged (charts/ and Chart.lock are in the workspace), but installing it fails at render time.
helm dependency update "$SANDBOX/invoicing" >/dev/null 2>&1
if helm install invoicing "$SANDBOX/invoicing" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: install succeeded — scenario is not broken"; exit 1
fi
grep -q "db.port is empty" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
[ -z "$(hm_release_status invoicing)" ] || { echo "setup: a release record exists"; exit 1; }
