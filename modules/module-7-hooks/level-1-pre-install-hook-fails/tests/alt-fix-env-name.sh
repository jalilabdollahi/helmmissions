#!/bin/bash
# Valid alternative: keep the script, rename the environment variable the chart passes to it.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/name: DATABASE_URL/name: LEDGER_DB_DSN/' "$SANDBOX/ledger-api/templates/migrate-job.yaml"
rm -f "$SANDBOX/ledger-api/templates/migrate-job.yaml.bak"
helm upgrade ledger-api ./ledger-api -n "$NS" --wait --timeout 90s
