#!/bin/bash
# Tempting hotfix: overwrite the ConfigMap with kubectl and bounce the pods. Helm still renders the path.
set -euo pipefail
source "$HM_LIB"

kubectl create configmap landing-nginx -n "$NS" --from-file=default.conf=site.conf --dry-run=client -o yaml | kubectl apply -n "$NS" -f -
kubectl rollout restart deployment/landing -n "$NS"
kubectl rollout status deployment/landing -n "$NS" --timeout=90s
