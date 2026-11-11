#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The chart renders fine locally, but the API server refuses the Deployment.
helm template geoip "$SANDBOX/geoip" -n "$NS" >/dev/null || { echo "setup: chart should render"; exit 1; }
if helm install hm-probe "$SANDBOX/geoip" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  helm uninstall hm-probe -n "$NS" >/dev/null 2>&1 || true
  echo "setup: the broken chart installed successfully - scenario is not broken"
  exit 1
fi
helm uninstall hm-probe -n "$NS" >/dev/null 2>&1 || true
grep -q "not declared in schema" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
