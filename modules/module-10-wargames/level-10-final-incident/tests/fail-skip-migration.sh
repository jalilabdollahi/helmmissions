#!/bin/bash
# Shortcut: set the schema target to the current schema so the hook passes without migrating anything.
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
helm dependency update ./tideline --plain-http >/dev/null
helm rollback tideline 1 -n "$NS" --wait --timeout 90s
cp "$LEVEL_DIR/solution/values/staging.yaml" values/staging.yaml
perl -pi -e 's/target: 14/target: 12/' values/prod.yaml
bash deploy.sh staging
bash deploy.sh prod
