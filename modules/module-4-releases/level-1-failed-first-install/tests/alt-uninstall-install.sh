#!/bin/bash
# Valid alternative: nothing worth keeping in a failed first revision — remove it and install again.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm uninstall invoice-api -n "$NS"
helm install invoice-api ./invoice-api -n "$NS" --wait --timeout 120s
