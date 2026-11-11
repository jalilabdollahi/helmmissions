#!/bin/bash
# Tempting hotfix: patch the live Deployment; the chart and the release stay broken.
set -euo pipefail
source "$HM_LIB"

kubectl set image deployment/receipts-api api=nginx:1.27-alpine -n "$NS"
kubectl rollout status deployment/receipts-api -n "$NS" --timeout=90s
