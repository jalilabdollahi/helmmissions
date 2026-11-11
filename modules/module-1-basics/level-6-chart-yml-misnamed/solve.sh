#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
rm -f "$SANDBOX/status-page/Chart.yml"
helm install status-page ./status-page -n "$NS" --wait --timeout 120s
