#!/bin/bash
# Valid alternative: guard the value in NOTES.txt and fall back to a port-forward hint with a URL.
set -euo pipefail
source "$HM_LIB"

cat > "$SANDBOX/status-page/templates/NOTES.txt" <<'TXT'
status-page {{ .Chart.AppVersion }} has been deployed as release "{{ .Release.Name }}".
{{- if and .Values.ingress .Values.ingress.host }}
Open the page: http://{{ .Values.ingress.host }}/
{{- else }}
Reach it locally:
  kubectl port-forward svc/{{ .Release.Name }} 8080:{{ .Values.service.port }}
  then open http://127.0.0.1:8080/
{{- end }}
TXT
helm install status-page ./status-page -n "$NS" --wait --timeout 90s
