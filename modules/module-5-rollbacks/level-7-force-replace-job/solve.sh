#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Give each seed version its own Job name, so an upgrade creates a new Job instead of patching the finished one.
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade catalog ./catalog-seed -n "$NS" --wait --timeout 120s
