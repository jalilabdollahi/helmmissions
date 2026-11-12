{{- define "catalog.image" -}}
{{- with .Values.global.imageRegistry }}{{ . }}/{{ end }}{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- define "catalog.selector" -}}
app.kubernetes.io/name: catalog
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
