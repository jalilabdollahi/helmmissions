#!/bin/bash
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"

# 1. Dependencies: the lock/charts directory are stale
helm dependency update ./tideline --plain-http
# 2. Stuck prod release: go back to the last good revision, which clears the pending operation
helm rollback tideline 1 -n "$NS" --wait --timeout 90s
# 3. Values: prod asks the hook to skip a schema version; staging points at the prod database
cp "$LEVEL_DIR/solution/values/prod.yaml" values/prod.yaml
cp "$LEVEL_DIR/solution/values/staging.yaml" values/staging.yaml
# 4. Ship it: staging first, then prod
bash deploy.sh staging
bash deploy.sh prod
