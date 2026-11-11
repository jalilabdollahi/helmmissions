#!/bin/bash
# Alternative: pick the API from the Kubernetes version instead of API discovery.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cat > "$SANDBOX/docs-portal/templates/_helpers.tpl" <<'EOF'
{{- define "docs-portal.ingressApiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.Version -}}
networking.k8s.io/v1
{{- else -}}
networking.k8s.io/v1beta1
{{- end -}}
{{- end -}}
EOF
helm install portal ./docs-portal -n "$NS" --wait --timeout 120s
