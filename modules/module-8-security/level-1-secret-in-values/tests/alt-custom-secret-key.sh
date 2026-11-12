#!/bin/bash
# Valid alternative: a differently named Secret and key, wired through values.
set -euo pipefail
source "$HM_LIB"

kubectl create secret generic finance-ledger-db -n "$NS" --from-literal=db-pass="alt-$(date +%s)-rotated" >/dev/null
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak -e 's/existingSecret: ledger-db-credentials/existingSecret: finance-ledger-db/' -e 's/existingSecretKey: password/existingSecretKey: db-pass/' ledger-api/values.yaml && rm -f ledger-api/values.yaml.bak
helm upgrade ledger-api ./ledger-api -n "$NS" -f ledger-api/values.yaml --wait --timeout 120s
