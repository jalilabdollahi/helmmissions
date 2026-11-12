#!/bin/bash
# Wrong fix: widen the allow rule to every pod in the namespace.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - <<'PY'
p='shopfront/templates/networkpolicy.yaml'
s=open(p).read()
s=s.replace('''        - podSelector:
            matchLabels:
              app.kubernetes.io/instance: {{ .Release.Name }}
              app.kubernetes.io/component: frontend
''','''        - podSelector: {}
''')
open(p,'w').write(s)
PY
helm upgrade shopfront ./shopfront -n "$NS" --wait --timeout 120s
sleep 5
