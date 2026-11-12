#!/bin/bash
# Deploy the ledger stack in dependency order (db -> api -> web).
set -euo pipefail
NS="${NS:-helmissions}"
cd "$(dirname "$0")"
helm upgrade --install ledger-db  ./ledger-db  -n "$NS" --wait --timeout 60s
helm upgrade --install ledger-api ./ledger-api -n "$NS" --wait --timeout 60s
helm upgrade --install ledger-web ./ledger-web -n "$NS" --wait --timeout 60s
