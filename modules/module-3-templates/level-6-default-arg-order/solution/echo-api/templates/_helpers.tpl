{{- define "echo-api.image" -}}
{{ .Values.image.repository }}:{{ default .Chart.AppVersion .Values.image.tag }}
{{- end -}}

{{- define "echo-api.selector" -}}
app.kubernetes.io/name: echo-api
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
