#!/bin/bash
set -euo pipefail
source "$HM_LIB"

kubectl label namespace "$NS" pod-security.kubernetes.io/enforce=restricted --overwrite >/dev/null
helm upgrade --install audit-gateway "$SANDBOX/audit-gateway" -n "$NS" >/dev/null
hm_assert_status audit-gateway deployed
for _ in $(seq 1 30); do
  ev="$(kubectl get events -n "$NS" 2>/dev/null || true)"
  grep -q 'violates PodSecurity "restricted' <<<"$ev" && exit 0
  sleep 2
done
echo "setup: PodSecurity rejection never appeared in events"; exit 1
