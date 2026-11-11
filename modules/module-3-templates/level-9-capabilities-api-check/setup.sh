#!/bin/bash
set -euo pipefail
source "$HM_LIB"

if helm install hm-probe "$SANDBOX/docs-portal" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  helm uninstall hm-probe -n "$NS" >/dev/null 2>&1 || true
  echo "setup: the broken chart installed successfully - scenario is not broken"
  exit 1
fi
grep -q 'no matches for kind "Ingress" in version "networking.k8s.io/v1beta1"' "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
