#!/bin/bash
# Another valid fix: correct the template and upgrade with --reset-values.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade receipts ./receipts -n "$NS" --reset-values --wait --timeout 120s
