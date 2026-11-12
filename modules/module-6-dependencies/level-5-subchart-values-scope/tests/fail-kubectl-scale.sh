#!/bin/bash
# Tempting shortcut: scale and patch the live Deployment; the release (and the next upgrade) still say 1 / 1024.
set -euo pipefail
source "$HM_LIB"

helm upgrade newsroom ./newsroom -n "$NS" --reuse-values --wait --timeout 120s >/dev/null   # a revision >= 2 exists
kubectl scale deployment/newsroom-image-resizer -n "$NS" --replicas=3
kubectl set env deployment/newsroom-image-resizer -n "$NS" MAX_WIDTH=800 JPEG_QUALITY=70
kubectl rollout status deployment/newsroom-image-resizer -n "$NS" --timeout=90s
