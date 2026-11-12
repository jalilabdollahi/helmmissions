#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./ledger-api
helm dependency update ./ledger-worker
helm upgrade ledger-api ./ledger-api -n "$NS" --wait --timeout 120s
helm upgrade ledger-worker ./ledger-worker -n "$NS" --wait --timeout 120s
