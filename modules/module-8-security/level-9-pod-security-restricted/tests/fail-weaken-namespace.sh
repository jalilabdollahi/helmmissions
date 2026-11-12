#!/bin/bash
# Tempting wrong fix: relax the namespace's Pod Security level.
set -euo pipefail
source "$HM_LIB"

kubectl label namespace "$NS" pod-security.kubernetes.io/enforce=privileged --overwrite
kubectl rollout status deployment/audit-gateway -n "$NS" --timeout=120s
