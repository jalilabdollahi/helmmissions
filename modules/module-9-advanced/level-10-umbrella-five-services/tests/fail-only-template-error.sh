#!/bin/bash
# Partial fix: the nil pointer is fixed and the release is deployed, but cart still ignores global.imageRegistry.
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/marketplace/charts/pricing/values.yaml" marketplace/charts/pricing/values.yaml
helm install marketplace ./marketplace -n "$NS" --wait --timeout 180s
