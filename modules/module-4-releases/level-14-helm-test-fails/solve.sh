#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
# Test hooks live in the stored release, so the fixed test only exists after an upgrade.
helm upgrade rating-service ./rating-service -n "$NS" --wait --timeout 90s
helm test rating-service -n "$NS" --timeout 60s
