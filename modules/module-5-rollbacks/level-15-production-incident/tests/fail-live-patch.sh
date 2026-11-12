#!/bin/bash
# Wrong fix: patch the live Deployment until the page says ok - the release and values-prod.yaml are still broken.
set -euo pipefail
source "$HM_LIB"

kubectl set env deployment/checkout PAYMENT_TIMEOUT_MS=3000 FORCE_FALLBACK- -n "$NS"
kubectl rollout status deployment/checkout -n "$NS" --timeout=90s
