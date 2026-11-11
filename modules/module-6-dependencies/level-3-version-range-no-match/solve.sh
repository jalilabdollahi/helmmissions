#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./searchdesk
helm install searchdesk ./searchdesk -n "$NS" --wait --timeout 120s
