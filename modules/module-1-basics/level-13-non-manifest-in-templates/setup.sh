#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm install helpdesk "$SANDBOX/helpdesk" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: install succeeded - scenario is not broken"; exit 1
fi
grep -q "YAML parse error on helpdesk/templates/usage-notes.yaml" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
