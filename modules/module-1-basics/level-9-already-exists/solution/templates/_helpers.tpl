{{- define "helmissions.name" -}}
{{- default .Chart.Name .Values.app.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "helmissions.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "helmissions.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "helmissions.labels" -}}
app.kubernetes.io/name: {{ include "helmissions.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
