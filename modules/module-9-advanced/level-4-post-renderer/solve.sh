#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/plugins/hm-cost-labeler/kustomization.yaml" plugins/hm-cost-labeler/kustomization.yaml
helm template edge-gateway ./edge-gateway -n "$NS" --post-renderer hm-cost-labeler >/dev/null
helm upgrade edge-gateway ./edge-gateway -n "$NS" --post-renderer hm-cost-labeler --wait --timeout 120s
