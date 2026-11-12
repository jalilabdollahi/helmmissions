#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if kubectl kustomize --enable-helm "$SANDBOX/platform" >"$HM_TMP/k.txt" 2>&1; then
  echo "setup: kustomize build succeeded — scenario is not broken"; exit 1
fi
grep -q "no chart found" "$HM_TMP/k.txt" || { cat "$HM_TMP/k.txt"; exit 1; }
