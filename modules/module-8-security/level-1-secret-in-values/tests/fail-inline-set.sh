#!/bin/bash
# Tempting wrong fix: scrub values.yaml, but keep passing a (new) password inline with --set.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/existingSecret: ledger-db-credentials/existingSecret: ""/' ledger-api/values.yaml && rm -f ledger-api/values.yaml.bak
helm upgrade ledger-api ./ledger-api -n "$NS" -f ledger-api/values.yaml --set db.password=N3w-rotated-pass --wait --timeout 120s
