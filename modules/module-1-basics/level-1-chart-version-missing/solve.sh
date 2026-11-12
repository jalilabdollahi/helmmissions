#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm install webapp ./webapp -n "$NS" --wait --timeout 120s
