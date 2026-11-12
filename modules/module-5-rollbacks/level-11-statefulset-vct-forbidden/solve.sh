#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Keep the new retention, restore the original volume request.
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade tsdb ./timeseries-db -n "$NS" --wait --timeout 120s
