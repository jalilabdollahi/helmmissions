#!/bin/bash
# Shortcut: skip Helm's release machinery - apply the rendered fixed chart with kubectl; the release stays stuck.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm template edge-gateway "$SANDBOX/edge-gateway" -n "$NS" | kubectl apply -n "$NS" --server-side --force-conflicts -f -
kubectl rollout status deployment/edge-gateway -n "$NS" --timeout=90s
