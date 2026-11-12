#!/bin/bash
# Tempting hotfix: delete the Ingress with kubectl. Helm's manifest still contains it.
set -euo pipefail
source "$HM_LIB"

kubectl delete ingress storefront -n "$NS"
