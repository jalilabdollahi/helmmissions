#!/bin/bash
# Another valid route: fix the file, install with an explicit release flow (upgrade --install).
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade --install pressroom ./pressroom -n "$NS" --wait --timeout 120s
