#!/bin/bash
# Production deploy of the checkout API
set -euo pipefail
helm upgrade --install checkout ./checkout \
  -n helmissions-prod --create-namespace \
  -f values-prod.yaml \
  -f values-base.yaml \
  --wait --timeout 120s
