#!/bin/bash
# Tempting hotfix: patch the live Deployment; the release (and values.yaml) still carry the typo.
set -euo pipefail
source "$HM_LIB"

kubectl set image deployment/ledger-api api=nginx:1.27-alpine -n "$NS"
kubectl rollout status deployment/ledger-api -n "$NS" --timeout=90s
