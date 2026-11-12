#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install metrics-proxy ./metrics-proxy -n helmissions-staging --create-namespace --wait --timeout 120s
