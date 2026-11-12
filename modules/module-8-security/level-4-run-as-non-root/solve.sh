#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade status-page ./status-page -n "$NS" --wait --timeout 120s
