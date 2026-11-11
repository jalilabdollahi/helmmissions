{{- define "geoip.selectorLabels" -}}
app: geoip
release: {{ .Release.Name }}
{{- end -}}
