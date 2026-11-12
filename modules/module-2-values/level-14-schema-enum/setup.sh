#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm install search-api "$SANDBOX/search-api" -n "$NS" >"$HM_TMP/out.txt" 2>&1; then
  echo "setup: install should have failed"; exit 1
fi
grep -q "values don't meet the specifications of the schema" "$HM_TMP/out.txt" || { cat "$HM_TMP/out.txt"; exit 1; }
