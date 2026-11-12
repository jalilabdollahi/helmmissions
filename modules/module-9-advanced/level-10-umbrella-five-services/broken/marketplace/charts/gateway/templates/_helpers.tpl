{{- define "gateway.image" -}}
{{- $registry := .Values.global.imageRegistry | default "" -}}
{{- if $registry }}{{ $registry }}/{{ end }}{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- define "gateway.labels" -}}
app.kubernetes.io/name: gateway
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: marketplace
{{- end -}}
