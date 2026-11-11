#!/bin/bash
# Alternative: a more compact lookup using dig and a default.
set -euo pipefail
source "$HM_LIB"

cat > "$SANDBOX/ledger-db/templates/secret.yaml" <<'EOF'
{{- $name := printf "%s-credentials" .Release.Name }}
{{- $existing := (lookup "v1" "Secret" .Release.Namespace $name).data | default dict }}
{{- $password := get $existing "password" | default (randAlphaNum (int .Values.auth.passwordLength) | b64enc) }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ $name }}
type: Opaque
data:
  password: {{ $password | quote }}
EOF
helm upgrade ledgerdb ./ledger-db -n "$NS" --wait --timeout 120s
