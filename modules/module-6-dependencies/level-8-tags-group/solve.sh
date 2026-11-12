#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./tradedesk
helm upgrade tradedesk ./tradedesk -n "$NS" --wait --timeout 120s
