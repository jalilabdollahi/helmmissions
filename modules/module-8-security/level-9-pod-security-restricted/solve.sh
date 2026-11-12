#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade audit-gateway ./audit-gateway -n "$NS" --wait --timeout 120s
