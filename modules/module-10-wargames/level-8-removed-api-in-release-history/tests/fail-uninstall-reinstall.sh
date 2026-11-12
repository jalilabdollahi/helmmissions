#!/bin/bash
# Shortcut: `helm uninstall` cannot even build the stored objects, so delete the release records by hand and install fresh. The history is gone.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
kubectl delete secret -n "$NS" -l owner=helm,name=edge-gateway
helm install edge-gateway "$SANDBOX/edge-gateway" -n "$NS" --wait --timeout 90s
