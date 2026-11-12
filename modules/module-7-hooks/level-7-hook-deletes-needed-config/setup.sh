#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The CI deploy has no --wait, so Helm reports success while the pod can never start.
helm install gateway "$SANDBOX/route-gateway" -n "$NS" >/dev/null
hm_assert_status gateway deployed
sleep 6
! kubectl get configmap gateway-routes -n "$NS" >/dev/null 2>&1 || { echo "setup: the ConfigMap survived"; exit 1; }
[ "$(hm_jsonpath deployment/gateway '{.status.readyReplicas}')" != "1" ] || { echo "setup: gateway is ready — scenario not broken"; exit 1; }
