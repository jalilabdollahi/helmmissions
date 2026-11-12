#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/marketplace/charts/pricing/values.yaml" marketplace/charts/pricing/values.yaml
helm template marketplace ./marketplace -n "$NS" >/dev/null   # renders now; cart still ignores the global
cp "$LEVEL_DIR/solution/marketplace/charts/cart/templates/_helpers.tpl" marketplace/charts/cart/templates/_helpers.tpl
cp "$LEVEL_DIR/solution/marketplace/charts/cart/values.yaml" marketplace/charts/cart/values.yaml
helm install marketplace ./marketplace -n "$NS" --wait --timeout 180s
