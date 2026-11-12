{{- define "ledger-worker.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "ledger-worker.labels" -}}
{{ include "ledger-worker.selectorLabels" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/part-of: ledger-platform
app.kubernetes.io/managed-by: helm
{{- end -}}
