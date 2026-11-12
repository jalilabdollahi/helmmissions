{{- define "notifier.image" -}}
{{- with .Values.global.imageRegistry }}{{ . }}/{{ end }}{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- define "notifier.selector" -}}
app.kubernetes.io/name: notifier
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
