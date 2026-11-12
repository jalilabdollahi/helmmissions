#!/bin/bash
# Wrong fix: patch the image in the cluster - pods recover but the release is still stuck in a pending-rollback state.
set -euo pipefail
source "$HM_LIB"

kubectl set image deployment/settlement-batch runner=traefik/whoami:v1.10 -n "$NS"
kubectl rollout status deployment/settlement-batch -n "$NS" --timeout=90s
