#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade --install shopfront "$SANDBOX/shopfront" -n "$NS" >/dev/null
hm_assert_status shopfront deployed
kubectl rollout status deploy/shopfront-backend -n "$NS" --timeout=90s >/dev/null
for _ in $(seq 1 45); do
  lg="$(kubectl logs deploy/shopfront-frontend -n "$NS" 2>/dev/null || true)"
  grep -q "catalog unreachable" <<<"$lg" && exit 0
  sleep 2
done
echo "setup: the frontend never reported the blocked connection"; exit 1
