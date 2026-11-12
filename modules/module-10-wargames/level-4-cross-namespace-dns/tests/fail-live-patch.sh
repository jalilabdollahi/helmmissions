#!/bin/bash
# Shortcut: patch live objects with kubectl; chart, values and release records stay as they were.
set -euo pipefail
source "$HM_LIB"
kubectl patch service orders-api -n helmissions-api --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":8080}]'
kubectl patch deployment orders-web -n helmissions-web --type=json -p '[{"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirst"},{"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"orders-api.helmissions-api"}]'
kubectl rollout status deployment/orders-web -n helmissions-web --timeout=90s
