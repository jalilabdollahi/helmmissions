#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm install status-page "$SANDBOX/status-page" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: install succeeded - scenario is not broken"; exit 1
fi
grep -q "Chart.yaml" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
