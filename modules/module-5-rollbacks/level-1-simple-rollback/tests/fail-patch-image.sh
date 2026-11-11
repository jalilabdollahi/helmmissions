#!/bin/bash
# Wrong fix: patch the image by hand - the pod is healthy but Helm still says revision 2 is current.
set -euo pipefail
source "$HM_LIB"

kubectl set image deployment/quotes-api quotes=traefik/whoami:v1.10 -n "$NS"
kubectl rollout status deployment/quotes-api -n "$NS" --timeout=90s
