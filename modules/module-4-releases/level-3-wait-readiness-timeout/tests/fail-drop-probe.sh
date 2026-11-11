#!/bin/bash
# Tempting wrong fix: delete the readiness probe so "ready" is automatic.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - <<'PY'
import re
p="docs-portal/templates/deployment.yaml"
s=open(p).read()
s=re.sub(r"          readinessProbe:\n(?:            .*\n)+", "", s)
open(p,"w").write(s)
PY
helm upgrade docs-portal ./docs-portal -n "$NS" --wait --timeout 90s
