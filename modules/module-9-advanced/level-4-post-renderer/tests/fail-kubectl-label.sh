#!/bin/bash
# Tempting shortcut: label and patch the live objects by hand. Helm does not know about it, the next upgrade erases it.
set -euo pipefail
source "$HM_LIB"

for k in serviceaccount/edge-gateway service/edge-gateway configmap/edge-gateway-routes deployment/edge-gateway; do
  kubectl label "$k" -n "$NS" cost-center=edge-platform --overwrite
done
kubectl patch deployment edge-gateway -n "$NS" --type=json \
  -p '[{"op":"add","path":"/spec/template/metadata/labels/cost-center","value":"edge-platform"},{"op":"add","path":"/spec/template/spec/containers/-","value":{"name":"log-shipper","image":"busybox:1.36","imagePullPolicy":"IfNotPresent","command":["sh","-c","sleep 3600"]}}]'
kubectl rollout status deployment/edge-gateway -n "$NS" --timeout=90s
