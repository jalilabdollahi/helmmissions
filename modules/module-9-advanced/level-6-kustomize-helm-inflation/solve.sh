#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/platform/kustomization.yaml" platform/kustomization.yaml
kubectl kustomize --enable-helm platform | kubectl apply -f -
kubectl rollout status deployment/catalog-api -n "$NS" --timeout=90s
