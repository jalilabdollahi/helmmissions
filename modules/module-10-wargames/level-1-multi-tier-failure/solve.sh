#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
# dependency order: the database first
helm upgrade --install ledger-db ./ledger-db -n "$NS" --wait --timeout 90s
bash deploy.sh
