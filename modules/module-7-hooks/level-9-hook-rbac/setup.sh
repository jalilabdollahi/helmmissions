#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install tenants "$SANDBOX/tenant-onboarding" -n "$NS" --timeout 90s >"$HM_TMP/install.txt" 2>&1 && { echo "setup: install succeeded — scenario not broken"; exit 1; }
hm_assert_status tenants failed
kubectl logs job/tenants-preflight -n "$NS" 2>&1 | grep -q "forbidden" || { echo "setup: preflight did not fail with a forbidden error"; exit 1; }
