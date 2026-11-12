#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The release as the edge team deployed it: no label, no sidecar.
helm install edge-gateway "$SANDBOX/edge-gateway" -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status edge-gateway deployed
# The teammate's plugin is installed (development mode: it points at the workspace) but broken.
helm plugin install "$SANDBOX/plugins/hm-cost-labeler" >/dev/null 2>&1
helm plugin list | grep -q '^hm-cost-labeler' || { echo "setup: plugin not installed"; exit 1; }
if helm template edge-gateway "$SANDBOX/edge-gateway" -n "$NS" --post-renderer hm-cost-labeler >"$HM_TMP/pr.txt" 2>&1; then
  echo "setup: post-renderer worked — scenario is not broken"; exit 1
fi
grep -q 'error while running post render' "$HM_TMP/pr.txt" || { cat "$HM_TMP/pr.txt"; exit 1; }
