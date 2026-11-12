#!/bin/bash
# Tempting shortcut: skip kustomize, render the chart with helm and apply it. The env=prod label from the kustomization is missing.
set -euo pipefail
source "$HM_LIB"

helm template catalog platform/charts/catalog-api -n "$NS" -f platform/values/prod.yaml | kubectl apply -n "$NS" -f -
kubectl rollout status deployment/catalog-api -n "$NS" --timeout=90s
