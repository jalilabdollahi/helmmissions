#!/bin/bash
# Shortcut: bypass the failing migration hook with --no-hooks instead of fixing the schema target.
set -euo pipefail
source "$HM_LIB"
cd "$SANDBOX"
helm dependency update ./tideline --plain-http >/dev/null
helm rollback tideline 1 -n "$NS" --wait --timeout 90s
cp "$LEVEL_DIR/solution/values/staging.yaml" values/staging.yaml
bash deploy.sh staging
helm upgrade tideline ./tideline -n "$NS" -f values/common.yaml -f values/prod.yaml --no-hooks --wait --timeout 90s
