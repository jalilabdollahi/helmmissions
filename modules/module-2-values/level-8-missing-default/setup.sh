#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install fetcher "$SANDBOX/fetcher" -n "$NS" >/dev/null
cm="$(kubectl get configmap fetcher-config -n "$NS" -o jsonpath='{.data.fetcher\.env}')"
echo "$cm" | grep -qx 'FETCH_TIMEOUT=' || { echo "setup: expected an empty FETCH_TIMEOUT"; exit 1; }
