#!/bin/bash
# Deploy step of the shipment-tracker pipeline.
# The target namespace comes from the environment (the pipeline sets NAMESPACE per environment).
set -euo pipefail

NAMESPACE="${NAMESPACE:-helmissions}"
CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)/shipment-tracker"

echo "Deploying shipment-tracker to namespace ${NAMESPACE}"
helm upgrade shipment-tracker "$CHART_DIR" \
  --namespace "$NAMESPACE" \
  --wait --timeout 90s
echo "Deploy finished"
