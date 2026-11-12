#!/bin/bash
# Valid alternative: fix the hook and `helm upgrade` the failed release (the hook is also a pre-upgrade hook).
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade ledger-api ./ledger-api -n "$NS" --wait --timeout 90s
