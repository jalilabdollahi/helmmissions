#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./helpdesk
helm upgrade helpdesk ./helpdesk -n "$NS" --wait --timeout 120s
