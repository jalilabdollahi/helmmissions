{{/*
Helpers for the mailer components. They take a dict, not the root context:
  include "mailer.fullname" (dict "ctx" $ "component" "api")
*/}}
{{- define "mailer.fullname" -}}
{{- printf "%s-%s" .ctx.Release.Name .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mailer.selectorLabels" -}}
app.kubernetes.io/name: {{ .ctx.Chart.Name }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}
