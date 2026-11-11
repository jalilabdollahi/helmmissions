#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install storefront "$SANDBOX/storefront" -n "$NS" --wait --timeout 120s >/dev/null
kubectl get ingress storefront -n "$NS" >/dev/null 2>&1 || { echo "setup: expected the Ingress to exist"; exit 1; }
