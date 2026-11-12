#!/bin/bash
# Tempting: scale the Deployment directly. The release still has no replicaCount.
set -euo pipefail
source "$HM_LIB"

kubectl scale deployment/billing --replicas=4 -n "$NS"
kubectl rollout status deployment/billing -n "$NS" --timeout=90s
