#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Prove the scenario is broken: the shipped deploy script must be rejected by Helm.
if bash "$SANDBOX/deploy.sh" >"$HM_TMP/deploy.txt" 2>&1; then
  echo "setup: deploy.sh succeeded — scenario is not broken"
  exit 1
fi
grep -qi "invalid release name" "$HM_TMP/deploy.txt" || { cat "$HM_TMP/deploy.txt"; exit 1; }
