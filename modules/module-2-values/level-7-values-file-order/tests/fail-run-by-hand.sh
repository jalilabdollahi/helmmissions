#!/bin/bash
# Tempting: run the right helm command once by hand and leave deploy.sh broken (the next pipeline run regresses).
set -euo pipefail
source "$HM_LIB"

helm upgrade checkout ./checkout -n helmissions-prod -f values-base.yaml -f values-prod.yaml --wait --timeout 120s
