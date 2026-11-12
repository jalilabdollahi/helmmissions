#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./booking --plain-http
helm install booking ./booking -n "$NS" --wait --timeout 120s
