{{- define "echo-api.image" -}}
{{ .Values.image.repository }}:{{ default .Values.image.tag .Chart.AppVersion }}
{{- end -}}

{{- define "echo-api.selector" -}}
app.kubernetes.io/name: echo-api
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
