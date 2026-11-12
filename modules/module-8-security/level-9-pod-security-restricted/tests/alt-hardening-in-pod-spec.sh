#!/bin/bash
# Valid alternative: set everything in the template and per container, nothing in values.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cp "$LEVEL_DIR/broken/audit-gateway/values.yaml" audit-gateway/values.yaml
python3 - <<'PY'
p='audit-gateway/templates/deployment.yaml'
s=open(p).read()
sc='''securityContext:
            runAsNonRoot: true
            runAsUser: 101
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: RuntimeDefault
'''
s=s.replace('''          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
''','          '+sc,1)
s=s.replace('''          {{- with .Values.containerSecurityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
''','          '+sc)
open(p,'w').write(s)
PY
helm upgrade audit-gateway ./audit-gateway -n "$NS" --wait --timeout 120s
