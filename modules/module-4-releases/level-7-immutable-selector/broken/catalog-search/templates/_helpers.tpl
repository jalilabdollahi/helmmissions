{{/* 1.1: adopt the recommended Kubernetes labels everywhere. */}}
{{- define "catalog-search.selectorLabels" -}}
app.kubernetes.io/name: catalog-search
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- define "catalog-search.labels" -}}
{{ include "catalog-search.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
