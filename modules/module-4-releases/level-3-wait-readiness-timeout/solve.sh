#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade docs-portal ./docs-portal -n "$NS" --wait --timeout 90s
