{{- define "inventory.selector" -}}
app.kubernetes.io/name: inventory
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
