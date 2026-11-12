#!/bin/bash
# Valid alternative: attach the pull secret to the namespace's default ServiceAccount instead of the chart values.
set -euo pipefail
source "$HM_LIB"

kubectl create secret docker-registry regcred -n "$NS" \
  --docker-server=localhost:5002 --docker-username=depot --docker-password='Ship-It-2026' >/dev/null
kubectl patch serviceaccount default -n "$NS" -p '{"imagePullSecrets":[{"name":"regcred"}]}' >/dev/null
kubectl rollout restart deployment/portal -n "$NS" >/dev/null
kubectl rollout status deployment/portal -n "$NS" --timeout=120s
