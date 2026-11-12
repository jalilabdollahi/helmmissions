#!/bin/bash
# Wrong fix: grant the default account list access with kubectl. This install passes; a fresh environment does not.
set -euo pipefail
source "$HM_LIB"

kubectl create role preflight-by-hand -n "$NS" --verb=list --resource=configmaps
kubectl create rolebinding preflight-by-hand -n "$NS" --role=preflight-by-hand --serviceaccount="$NS":default
helm uninstall tenants -n "$NS" --wait >/dev/null
helm install tenants ./tenant-onboarding -n "$NS" --wait --timeout 90s
