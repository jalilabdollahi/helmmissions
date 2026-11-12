{{- define "cart.image" -}}
{{- with .Values.global.imageRegistry }}{{ . }}/{{ end }}{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- define "cart.selector" -}}
app.kubernetes.io/name: cart
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
