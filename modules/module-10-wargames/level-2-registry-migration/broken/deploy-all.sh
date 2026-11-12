#!/bin/bash
set -euo pipefail
NS="${NS:-helmissions}"
cd "$(dirname "$0")"
for rel in shop-cart shop-search shop-media; do
  helm upgrade --install "$rel" "./$rel" -n "$NS" -f values/global.yaml -f "values/$rel.yaml" --wait --timeout 90s
done
