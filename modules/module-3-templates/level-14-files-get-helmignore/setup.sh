#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install site "$SANDBOX/legacy-site" -n "$NS" >/dev/null
for _ in $(seq 1 20); do
  kubectl get configmap site-nginx -n "$NS" >/dev/null 2>&1 && break
  sleep 1
done
size="$(kubectl get configmap site-nginx -n "$NS" -o jsonpath='{.data.default\.conf}' | tr -d '[:space:]' | wc -c | tr -d ' ')"
[ "$size" = "0" ] || { echo "setup: the ConfigMap is not empty (size $size)"; exit 1; }
sleep 6
ready="$(kubectl get deploy site -n "$NS" -o jsonpath='{.status.readyReplicas}')"
[ "${ready:-0}" = "0" ] || { echo "setup: the pod is unexpectedly ready"; exit 1; }
