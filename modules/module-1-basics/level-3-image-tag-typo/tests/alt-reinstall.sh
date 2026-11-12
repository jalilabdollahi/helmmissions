#!/bin/bash
# Valid but heavier: fix the file, uninstall and install again (history is not a requirement here).
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/1.27-alpien/1.27-alpine/' "$SANDBOX/ledger-api/values.yaml" && rm -f "$SANDBOX/ledger-api/values.yaml.bak"
helm uninstall ledger-api -n "$NS"
helm install ledger-api ./ledger-api -n "$NS" --wait --timeout 120s
