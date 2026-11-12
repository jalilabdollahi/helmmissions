#!/bin/bash
# Deploys the storefront chart. Used by the shop team's pipeline.
set -euo pipefail
cd "$(dirname "$0")"

helm install shop-frontend ./storefront \
  --namespace helmissions \
  --wait --timeout 120s
