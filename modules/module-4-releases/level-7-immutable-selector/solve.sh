#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade catalog-search ./catalog-search -n "$NS" --wait --timeout 120s
