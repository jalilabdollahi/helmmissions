#!/bin/bash
# Valid alternative: leave init alone and push the migration Job after it instead.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/"helm.sh\/hook-weight": "0"/"helm.sh\/hook-weight": "20"/' "$SANDBOX/order-service/templates/db-migrate-job.yaml"
rm -f "$SANDBOX/order-service/templates/db-migrate-job.yaml.bak"
helm upgrade orders ./order-service -n "$NS" --wait --timeout 90s
