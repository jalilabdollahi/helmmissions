#!/bin/bash
# Valid alternative: fix render.sh (write the file the kustomization expects) instead of the kustomization,
# and run the upgrade with the post-renderer plugin.
set -euo pipefail
source "$HM_LIB"

sed 's#all.yaml#rendered.yaml#' plugins/hm-cost-labeler/render.sh > "$HM_TMP/render.sh"
cp "$HM_TMP/render.sh" plugins/hm-cost-labeler/render.sh
helm upgrade edge-gateway ./edge-gateway -n "$NS" --post-renderer hm-cost-labeler --wait --timeout 120s
