#!/bin/bash
# Partial fix: global registry and tag fixed, but the subchart that ignores global.imageRegistry is left alone.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cp "$LEVEL_DIR/broken/shop-search/charts/indexer/templates/deployment.yaml" "$SANDBOX/shop-search/charts/indexer/templates/deployment.yaml"
cp "$LEVEL_DIR/broken/shop-search/charts/indexer/values.yaml" "$SANDBOX/shop-search/charts/indexer/values.yaml"
cd "$SANDBOX"
for rel in shop-cart shop-search shop-media; do
  helm upgrade "$rel" "./$rel" -n "$NS" -f values/global.yaml -f "values/$rel.yaml" --timeout 30s || true
done
