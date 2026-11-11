#!/bin/bash
# Valid: create the namespace with kubectl, then install normally.
set -euo pipefail
source "$HM_LIB"

kubectl create namespace helmissions-staging
helm install metrics-proxy ./metrics-proxy -n helmissions-staging --wait --timeout 120s
