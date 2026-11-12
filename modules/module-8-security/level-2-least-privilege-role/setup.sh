#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade --install flag-sync "$SANDBOX/flag-sync" -n "$NS" >/dev/null
hm_assert_status flag-sync deployed
for _ in $(seq 1 45); do
  logs="$(kubectl logs deploy/flag-sync -n "$NS" 2>/dev/null || true)"
  echo "$logs" | grep -q "configmaps -> 403" && exit 0
  sleep 2
done
echo "setup: the 403 never showed up in the pod log"; exit 1
