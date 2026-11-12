#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm install profile-svc "$SANDBOX/profile-svc" -n "$NS" -f "$SANDBOX/values-staging.yaml" >"$HM_TMP/out.txt" 2>&1; then
  echo "setup: the staging install should have failed"; exit 1
fi
grep -q "nil pointer evaluating interface {}.redis" "$HM_TMP/out.txt" || { cat "$HM_TMP/out.txt"; exit 1; }
