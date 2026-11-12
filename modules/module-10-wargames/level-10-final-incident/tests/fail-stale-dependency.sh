#!/bin/bash
# Partial fix: stuck release and values repaired, but the stale cache dependency is never refreshed.
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
helm rollback tideline 1 -n "$NS" --wait --timeout 90s
cp "$LEVEL_DIR/solution/values/prod.yaml" values/prod.yaml
cp "$LEVEL_DIR/solution/values/staging.yaml" values/staging.yaml
bash deploy.sh staging
bash deploy.sh prod
