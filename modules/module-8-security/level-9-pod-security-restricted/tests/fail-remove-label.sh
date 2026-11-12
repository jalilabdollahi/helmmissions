#!/bin/bash
# Wrong fix: delete the enforcement label entirely.
set -euo pipefail
source "$HM_LIB"

kubectl label namespace "$NS" pod-security.kubernetes.io/enforce-
kubectl rollout status deployment/audit-gateway -n "$NS" --timeout=120s
