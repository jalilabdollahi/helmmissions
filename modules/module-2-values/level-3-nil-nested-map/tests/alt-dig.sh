#!/bin/bash
# Another valid fix: dig with defaults in the template.
set -euo pipefail
source "$HM_LIB"

cat > profile-svc/templates/configmap.yaml <<'TPL'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  LOG_LEVEL: {{ .Values.logLevel | quote }}
  CACHE_HOST: {{ dig "cache" "redis" "host" "" .Values.AsMap | quote }}
  CACHE_PORT: {{ dig "cache" "redis" "port" 6379 .Values.AsMap | quote }}
TPL
helm install profile-svc ./profile-svc -n "$NS" -f values-staging.yaml --wait --timeout 120s
