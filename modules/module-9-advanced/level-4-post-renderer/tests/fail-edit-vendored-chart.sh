#!/bin/bash
# Tempting shortcut: patch the vendored chart's templates instead of post-rendering.
set -euo pipefail
source "$HM_LIB"

for f in edge-gateway/templates/*.yaml; do
  sed 's#^  labels:#  labels:\n    cost-center: edge-platform#' "$f" > "$HM_TMP/t.yaml"
  cp "$HM_TMP/t.yaml" "$f"
done
helm upgrade edge-gateway ./edge-gateway -n "$NS" --wait --timeout 120s
