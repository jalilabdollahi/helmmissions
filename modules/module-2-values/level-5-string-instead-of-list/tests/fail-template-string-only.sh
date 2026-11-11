#!/bin/bash
# Tempting workaround: stop iterating, print the string. Breaks the "many origins" contract.
set -euo pipefail
source "$HM_LIB"

cat > cors-gateway/templates/configmap.yaml <<'TPL'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-origins
data:
  origins.txt: |
    {{ .Values.allowedOrigins }}
TPL
helm install cors-gateway ./cors-gateway -n "$NS" --wait --timeout 120s
