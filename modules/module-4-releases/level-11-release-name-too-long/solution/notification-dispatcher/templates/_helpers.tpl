{{/* Full name of every object: <release>-<chart>, or fullnameOverride. Kubernetes DNS labels (Services) max out at 63 characters. */}}
{{- define "notification-dispatcher.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "notification-dispatcher.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "notification-dispatcher.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "notification-dispatcher.selectorLabels" -}}
app.kubernetes.io/name: {{ include "notification-dispatcher.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "notification-dispatcher.labels" -}}
{{ include "notification-dispatcher.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
