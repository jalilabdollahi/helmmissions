#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm install audit-log "$SANDBOX/audit-log" -n "$NS" >"$HM_TMP/out.txt" 2>&1; then
  echo "setup: install should have failed"; exit 1
fi
grep -q "found character that cannot start any token" "$HM_TMP/out.txt" || { cat "$HM_TMP/out.txt"; exit 1; }
