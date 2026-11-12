#!/bin/bash
# Valid alternative: no new ServiceAccount; Role and RoleBinding for the namespace's default account, both as hooks.
set -euo pipefail
source "$HM_LIB"

cat > "$SANDBOX/tenant-onboarding/templates/preflight-rbac.yaml" <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ .Release.Name }}-preflight
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-10"
    "helm.sh/hook-delete-policy": before-hook-creation
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ .Release.Name }}-preflight
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-10"
    "helm.sh/hook-delete-policy": before-hook-creation
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
helm install tenants ./tenant-onboarding -n "$NS" --wait --timeout 90s
