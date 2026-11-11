#!/bin/bash
# Tempting wrong fix: push a "fixed" upgrade instead of going back to the known-good revision.
set -euo pipefail
source "$HM_LIB"

helm upgrade quotes-api "$LEVEL_DIR/assets/quotes-api" -n "$NS" --set image.tag=v1.10 --wait --timeout 90s
