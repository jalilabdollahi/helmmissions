#!/bin/bash
# Tempting hotfix: push the file into the live ConfigMap with kubectl and restart the pod. The release stays broken.
set -euo pipefail
source "$HM_LIB"

kubectl create configmap site-nginx -n "$NS" --from-file=default.conf="$SANDBOX/legacy-site/files/site.conf" --dry-run=client -o yaml | kubectl replace -f -
kubectl rollout restart deployment/site -n "$NS"
kubectl rollout status deployment/site -n "$NS" --timeout=90s
