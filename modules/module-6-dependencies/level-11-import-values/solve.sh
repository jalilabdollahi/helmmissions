#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./invoicing
helm install invoicing ./invoicing -n "$NS" --wait --timeout 120s
