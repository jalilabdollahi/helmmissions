#!/bin/bash
# Valid alternative: leave kustomization.yaml alone and rename the folders/files it already points at.
set -euo pipefail
source "$HM_LIB"

mv platform/charts platform/helm-charts
mv platform/values/prod.yaml platform/values-prod.yaml
kubectl kustomize --enable-helm platform | kubectl apply -f -
kubectl rollout status deployment/catalog-api -n "$NS" --timeout=90s
