#!/bin/bash
# Tempting wrong fix: add the Role and RoleBinding as ordinary templates. They are only created after the
# pre-install hooks have finished, so the preflight Job is still refused.
set -euo pipefail
source "$HM_LIB"

cat > "$SANDBOX/tenant-onboarding/templates/preflight-rbac.yaml" <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ .Release.Name }}-preflight
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ .Release.Name }}-preflight
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ .Release.Name }}-preflight
subjects:
  - kind: ServiceAccount
    name: default
    namespace: {{ .Release.Namespace }}
YAML
helm uninstall tenants -n "$NS" --wait >/dev/null
helm install tenants ./tenant-onboarding -n "$NS" --timeout 60s || true
