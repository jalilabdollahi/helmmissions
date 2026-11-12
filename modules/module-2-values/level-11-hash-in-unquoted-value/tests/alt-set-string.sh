#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade ledger-api ./ledger-api -n "$NS" --set-string 'db.password=Harbor Light #2024' --wait --timeout 120s
