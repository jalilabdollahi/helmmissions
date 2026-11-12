#!/bin/bash
# Valid alternative: same aliases, values handed over with --set instead of relying on the file only.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./inventory
helm install inventory ./inventory -n "$NS" --set primary.mode=readwrite --set replica.mode=readonly --wait --timeout 120s
