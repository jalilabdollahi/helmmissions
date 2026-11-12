#!/bin/bash
# Wrong fix: the password is moved into a second values file that is still plaintext in the workspace.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
sed -i.bak 's/existingSecret: ledger-db-credentials/existingSecret: ""/' ledger-api/values.yaml && rm -f ledger-api/values.yaml.bak
printf 'db:\n  password: "Rotated-but-still-in-git-1"\n' > ledger-api/values-prod.yaml
helm upgrade ledger-api ./ledger-api -n "$NS" -f ledger-api/values.yaml -f ledger-api/values-prod.yaml --wait --timeout 120s
