#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
# Test hooks are stored in the release revision, so the fixed annotation needs an upgrade first.
helm upgrade search ./inventory-search -n "$NS" --wait --timeout 90s
helm test search -n "$NS" --timeout 60s
