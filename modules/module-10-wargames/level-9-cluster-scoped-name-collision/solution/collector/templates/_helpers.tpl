{{/* Cluster-scoped objects (ClusterRole, ClusterRoleBinding, PriorityClass) share one global name space: scope them by namespace and release. */}}
{{- define "collector.scope" -}}
{{ .Release.Namespace }}-{{ .Release.Name }}
{{- end -}}
