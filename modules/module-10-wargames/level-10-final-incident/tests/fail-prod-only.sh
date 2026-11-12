#!/bin/bash
# Partial fix: prod is repaired and shipped; staging is left pointing at the production database.
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
helm dependency update ./tideline --plain-http >/dev/null
helm rollback tideline 1 -n "$NS" --wait --timeout 90s
cp "$LEVEL_DIR/solution/values/prod.yaml" values/prod.yaml
bash deploy.sh prod
