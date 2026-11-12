#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install payments "$SANDBOX/payments" -n "$NS" --wait --timeout 120s >/dev/null
n="$(hm_endpoints_count payments)"
[ "$n" = "0" ] || { echo "setup: expected 0 endpoints, got $n"; exit 1; }
