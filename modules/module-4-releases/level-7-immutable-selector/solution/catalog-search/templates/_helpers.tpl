{{/* 1.1: recommended Kubernetes labels on objects and pods; the selector keeps the labels of 1.0 (immutable). */}}
{{- define "catalog-search.selectorLabels" -}}
app: catalog-search
{{- end }}
{{- define "catalog-search.labels" -}}
{{ include "catalog-search.selectorLabels" . }}
app.kubernetes.io/name: catalog-search
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
