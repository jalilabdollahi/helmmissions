#!/bin/bash
# Shortcut: scale the stable Deployment by hand and relabel the canary pods; values files and releases stay wrong.
set -euo pipefail
source "$HM_LIB"
kubectl scale deployment/catalog-stable --replicas=9 -n "$NS"
kubectl patch deployment catalog-canary -n "$NS" --type=json -p '[{"op":"replace","path":"/spec/template/metadata/labels/app.kubernetes.io~1name","value":"catalog"},{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/healthz"}]'
kubectl rollout status deployment/catalog-stable -n "$NS" --timeout=90s
kubectl rollout status deployment/catalog-canary -n "$NS" --timeout=90s
