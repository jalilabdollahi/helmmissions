{{- define "cart.image" -}}
{{- if .Values.imageRegistry }}{{ .Values.imageRegistry }}/{{ end }}{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- define "cart.selector" -}}
app.kubernetes.io/name: cart
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
