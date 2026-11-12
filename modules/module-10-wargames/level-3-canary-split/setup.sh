#!/bin/bash
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
helm install catalog-stable ./catalog -n "$NS" -f values-stable.yaml --wait --timeout 60s >/dev/null
helm install catalog-canary ./catalog -n "$NS" -f values-canary.yaml --wait --timeout 25s >/dev/null 2>&1 || true

hm_assert_status catalog-stable deployed
hm_assert_status catalog-canary failed
[ "$(hm_endpoints_count catalog)" = "1" ] || { echo "setup: expected exactly one endpoint behind the Service"; exit 1; }
