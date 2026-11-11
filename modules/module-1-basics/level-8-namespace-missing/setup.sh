#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Make sure the staging namespace really does not exist (a previous run may have left it terminating).
kubectl delete namespace helmissions-staging --ignore-not-found --wait=true >/dev/null 2>&1 || true
if helm install metrics-proxy "$SANDBOX/metrics-proxy" -n helmissions-staging >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: install succeeded - scenario is not broken"; exit 1
fi
grep -q 'namespaces "helmissions-staging" not found' "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
