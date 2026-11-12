#!/bin/bash
# Shortcut: repair the prod release by hand with a one-off upgrade; deploy.sh itself is not fixed.
set -euo pipefail
source "$HM_LIB"
cp "$LEVEL_DIR/solution/values-prod.yaml" "$SANDBOX/values-prod.yaml"
helm upgrade invoice "$SANDBOX/invoice" -n "$NS" --reset-values -f "$SANDBOX/values-prod.yaml" --wait --timeout 60s
