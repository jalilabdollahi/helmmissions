#!/bin/bash
# Valid alternative: keep a probe but make it a TCP check instead of an HTTP path.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - <<'PY'
p="docs-portal/templates/deployment.yaml"
s=open(p).read()
s=s.replace("            httpGet:\n              path: {{ .Values.readiness.path }}\n              port: http\n","            tcpSocket:\n              port: http\n")
open(p,"w").write(s)
PY
helm upgrade docs-portal ./docs-portal -n "$NS" --wait --timeout 90s
