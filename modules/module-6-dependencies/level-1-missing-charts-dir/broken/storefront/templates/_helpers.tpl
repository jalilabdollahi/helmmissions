{{- define "storefront.labels" -}}
app.kubernetes.io/name: storefront
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
