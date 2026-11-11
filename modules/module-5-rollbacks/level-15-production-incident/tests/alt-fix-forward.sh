#!/bin/bash
# Valid alternative: no rollback at all - fix values-prod.yaml, remove the manual hotfix, deploy forward.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
kubectl set env deployment/checkout FORCE_FALLBACK- -n "$NS"
bash ci/deploy.sh
