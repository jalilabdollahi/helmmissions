#!/bin/bash
set -euo pipefail
source "$HM_LIB"

kubectl create secret generic ledger-db-credentials -n "$NS" --from-literal=password="$(head -c 18 /dev/urandom | base64 | tr -d '/+=')" >/dev/null
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm upgrade ledger-api ./ledger-api -n "$NS" -f ledger-api/values.yaml --wait --timeout 120s
