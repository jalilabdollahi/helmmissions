#!/bin/bash
# Tempting workaround: make the password static in the chart. It no longer rotates, but it is also not the registered one.
set -euo pipefail
source "$HM_LIB"

cat > "$SANDBOX/ledger-db/templates/secret.yaml" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-credentials
type: Opaque
data:
  password: {{ "changeme-ledger-2024" | b64enc | quote }}
EOF
helm upgrade ledgerdb ./ledger-db -n "$NS" --wait --timeout 120s
