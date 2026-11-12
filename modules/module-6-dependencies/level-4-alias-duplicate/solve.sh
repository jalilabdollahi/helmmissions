#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./inventory
helm install inventory ./inventory -n "$NS" --wait --timeout 120s
