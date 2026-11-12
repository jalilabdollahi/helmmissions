#!/bin/bash
# Tempting wrong fix: recreate the ConfigMap with kubectl. Pods start, but Helm does not own the config.
set -euo pipefail
source "$HM_LIB"

kubectl create configmap gateway-routes -n "$NS" --from-literal=default.conf='server { listen 80; location = /healthz { return 200 "ok\n"; } location / { return 200 "gateway routes v3: by hand\n"; } }'
kubectl rollout restart deployment/gateway -n "$NS"
kubectl rollout status deployment/gateway -n "$NS" --timeout=60s
