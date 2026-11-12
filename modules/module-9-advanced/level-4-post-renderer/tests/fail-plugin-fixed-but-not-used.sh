#!/bin/bash
# Partial fix: the plugin is repaired, but the upgrade is run without --post-renderer.
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/plugins/hm-cost-labeler/kustomization.yaml" plugins/hm-cost-labeler/kustomization.yaml
helm upgrade edge-gateway ./edge-gateway -n "$NS" --wait --timeout 120s
