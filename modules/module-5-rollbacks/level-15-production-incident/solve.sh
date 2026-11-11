#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Revision 2 (the obvious target) is the one with the retired gateway: go back to revision 1, the last good one.
helm rollback checkout 1 -n "$NS" --wait --timeout 90s
# The rollback does not touch what is in no revision: remove the manual hotfix.
kubectl set env deployment/checkout FORCE_FALLBACK- -n "$NS"
kubectl rollout status deployment/checkout -n "$NS" --timeout=90s
# Make it durable: fix the values the pipeline deploys with, and redeploy through the pipeline.
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
bash ci/deploy.sh
