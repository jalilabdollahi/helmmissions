#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade upload-proxy ./upload-proxy -n "$NS" --wait --timeout 120s
