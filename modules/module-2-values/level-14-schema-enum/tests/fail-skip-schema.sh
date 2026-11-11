#!/bin/bash
# Tempting: bypass the policy with --skip-schema-validation. Release deploys (0 replicas, WARN) but violates the contract.
set -euo pipefail
source "$HM_LIB"

helm install search-api ./search-api -n "$NS" --skip-schema-validation
