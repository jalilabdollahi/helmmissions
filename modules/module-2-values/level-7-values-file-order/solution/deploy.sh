#!/bin/bash
# Production deploy of the checkout API
set -euo pipefail
helm upgrade --install checkout ./checkout \
  -n helmissions-prod --create-namespace \
  -f values-base.yaml \
  -f values-prod.yaml \
  --wait --timeout 120s
