#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
# Clean up what the earlier uninstall leaked, then prove the chart does it itself.
kubectl delete pvc exports-scratch -n "$NS"
helm install exports ./export-batch -n "$NS" --wait --timeout 90s
helm uninstall exports -n "$NS" --timeout 90s
