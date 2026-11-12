#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install inventory "$SANDBOX/inventory" -n "$NS" --wait --timeout 120s >/dev/null
[ "$(hm_endpoints_count inventory)" -ge 1 ] || { echo "setup: service has no endpoints"; exit 1; }
if hm_http_check "http://inventory.$NS.svc/" >/dev/null 2>&1; then
  echo "setup: the service already answers - scenario is not broken"; exit 1
fi
