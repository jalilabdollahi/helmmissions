#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm install orders "$SANDBOX/orders-api" -n "$NS" >/dev/null
for _ in $(seq 1 30); do
  host="$(kubectl get deploy orders-api -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].env[0].value}' 2>/dev/null || true)"
  [ -n "$host" ] && break
  sleep 1
done
case "$host" in *"{{"*) ;; *) echo "setup: DB_HOST is '$host', expected literal braces"; exit 1 ;; esac
kubectl rollout status deploy/orders-db -n "$NS" --timeout=90s >/dev/null
sleep 8
ready="$(kubectl get deploy orders-api -n "$NS" -o jsonpath='{.status.readyReplicas}')"
[ "${ready:-0}" = "0" ] || { echo "setup: the API pod is unexpectedly ready"; exit 1; }
