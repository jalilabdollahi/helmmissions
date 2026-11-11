#!/bin/bash
# Tempting wrong fix: correct the test template and re-run `helm test`. The release still holds the old hook.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm test rating-service -n "$NS" --timeout 60s || true
