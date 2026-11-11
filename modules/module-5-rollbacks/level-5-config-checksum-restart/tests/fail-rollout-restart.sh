#!/bin/bash
# Tempting wrong fix: restart the pods by hand. Works today, breaks again at the next config change/rollback.
set -euo pipefail
source "$HM_LIB"

kubectl rollout restart deployment/edge-throttle -n "$NS"
kubectl rollout status deployment/edge-throttle -n "$NS" --timeout=90s
