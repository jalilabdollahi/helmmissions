{{- define "docs-portal.ingressApiVersion" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/ingress" -}}
networking.k8s.io/v1
{{- else -}}
networking.k8s.io/v1beta1
{{- end -}}
{{- end -}}
