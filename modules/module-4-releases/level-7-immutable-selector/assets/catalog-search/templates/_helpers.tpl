{{- define "catalog-search.selectorLabels" -}}
app: catalog-search
{{- end }}
{{- define "catalog-search.labels" -}}
{{ include "catalog-search.selectorLabels" . }}
{{- end }}
