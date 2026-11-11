#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install status-page "$SANDBOX/status-page" -n "$NS" >"$HM_TMP/install.txt" 2>&1 && { echo "setup: install succeeded"; exit 1; }
grep -q "NOTES.txt" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
[ -z "$(hm_release_status status-page)" ] || { echo "setup: a release record exists"; exit 1; }
