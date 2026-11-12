#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Prove the scenario is broken: installing the chart as shipped must fail.
if helm install webapp "$SANDBOX/webapp" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: the broken chart installed successfully — scenario is not broken"
  exit 1
fi
grep -qi "version is required" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
