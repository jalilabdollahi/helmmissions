#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade tax-engine ./tax-engine -n "$NS" --wait --timeout 90s
