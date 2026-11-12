#!/bin/bash
# Valid alternative: fix the chart, uninstall and install again.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm uninstall gateway -n "$NS" --wait >/dev/null
helm install gateway ./route-gateway -n "$NS" --wait --timeout 90s
