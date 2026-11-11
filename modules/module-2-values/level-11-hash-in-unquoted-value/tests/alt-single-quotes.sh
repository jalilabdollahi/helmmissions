#!/bin/bash
set -euo pipefail
source "$HM_LIB"

sed -i.bak "s/password: Harbor Light #2024/password: 'Harbor Light #2024'/" ledger-api/values.yaml
helm upgrade ledger-api ./ledger-api -n "$NS" --wait --timeout 120s
