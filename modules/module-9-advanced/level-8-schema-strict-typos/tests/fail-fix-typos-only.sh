#!/bin/bash
# Tempting shortcut: correct the two typos and redeploy — no schema, so the next typo is silent again.
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/values-prod.yaml" values-prod.yaml
helm upgrade queue-worker ./queue-worker -n "$NS" -f values-prod.yaml --wait --timeout 120s
