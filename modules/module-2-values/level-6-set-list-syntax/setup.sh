#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if bash "$SANDBOX/install.sh" >"$HM_TMP/out.txt" 2>&1; then
  echo "setup: install.sh should have failed"; exit 1
fi
grep -q "failed parsing --set data" "$HM_TMP/out.txt" || { cat "$HM_TMP/out.txt"; exit 1; }
