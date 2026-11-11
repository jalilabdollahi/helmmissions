#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm install cors-gateway "$SANDBOX/cors-gateway" -n "$NS" >"$HM_TMP/out.txt" 2>&1; then
  echo "setup: install should have failed"; exit 1
fi
grep -q "range can't iterate over https://shop.example" "$HM_TMP/out.txt" || { cat "$HM_TMP/out.txt"; exit 1; }
