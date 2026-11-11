{{/* ConfigMap name that changes whenever the flag data changes */}}
{{- define "feature-flags.configName" -}}
{{ .Release.Name }}-flags-{{ .Values.flags | toJson | sha256sum | trunc 8 }}
{{- end -}}
