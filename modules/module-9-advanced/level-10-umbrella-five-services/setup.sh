#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm install marketplace "$SANDBOX/marketplace" -n "$NS" --dry-run=client >"$HM_TMP/inst.txt" 2>&1; then
  echo "setup: the umbrella rendered — scenario is not broken"; exit 1
fi
grep -q 'nil pointer evaluating interface {}.cpu' "$HM_TMP/inst.txt" || { cat "$HM_TMP/inst.txt"; exit 1; }
