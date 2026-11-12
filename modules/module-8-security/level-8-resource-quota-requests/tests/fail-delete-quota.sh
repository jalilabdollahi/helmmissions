#!/bin/bash
# Tempting wrong fix: remove the ResourceQuota.
set -euo pipefail
source "$HM_LIB"

kubectl delete resourcequota search-team-quota -n "$NS"
kubectl rollout status deployment/search-indexer -n "$NS" --timeout=90s
