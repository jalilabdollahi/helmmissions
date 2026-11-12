#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm install hm-probe "$SANDBOX/payments-gw" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  helm uninstall hm-probe -n "$NS" >/dev/null 2>&1 || true
  echo "setup: the broken chart installed successfully - scenario is not broken"
  exit 1
fi
helm uninstall hm-probe -n "$NS" >/dev/null 2>&1 || true
grep -q "illegal base64 data" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
