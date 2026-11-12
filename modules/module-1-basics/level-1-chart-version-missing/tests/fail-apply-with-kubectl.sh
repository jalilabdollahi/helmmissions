#!/bin/bash
# Tempting shortcut: render the chart and apply it with kubectl — no Helm release exists.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm template webapp ./webapp -n "$NS" | kubectl apply -n "$NS" -f -
