#!/bin/bash
# Valid alternative: the credentials are in the chart's values anyway — delete the kept Secret.
set -euo pipefail
source "$HM_LIB"

kubectl delete secret db-credentials -n "$NS"
helm install storefront ./storefront -n "$NS" --wait --timeout 120s
