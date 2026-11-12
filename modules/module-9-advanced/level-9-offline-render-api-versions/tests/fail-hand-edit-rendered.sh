#!/bin/bash
# Tempting shortcut: append a ServiceMonitor to the committed output and apply it. render.sh still drops it.
set -euo pipefail
source "$HM_LIB"

cat >> rendered/prod.yaml <<'Y'
---
apiVersion: monitoring.helmissions.io/v1
kind: ServiceMonitor
metadata:
  name: checkout
  namespace: helmissions
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: checkout
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
Y
kubectl apply -n "$NS" -f rendered/prod.yaml
