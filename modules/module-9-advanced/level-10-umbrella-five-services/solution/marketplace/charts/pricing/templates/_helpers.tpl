{{- define "pricing.image" -}}
{{- $registry := .Values.global.imageRegistry | default "" -}}
{{- if $registry }}{{ $registry }}/{{ end }}{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- define "pricing.selector" -}}
app.kubernetes.io/name: pricing
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
