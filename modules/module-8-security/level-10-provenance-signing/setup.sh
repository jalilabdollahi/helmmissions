#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cd "$SANDBOX"
rm -rf dist
if bash deploy.sh >"$HM_TMP/deploy.txt" 2>&1; then echo "setup: deploy.sh succeeded"; exit 1; fi
grep -q "provenance file" "$HM_TMP/deploy.txt" || { cat "$HM_TMP/deploy.txt"; echo "setup: unexpected failure"; exit 1; }
[ -z "$(hm_release_status payments-gateway)" ] || { echo "setup: release exists"; exit 1; }
rm -rf dist
