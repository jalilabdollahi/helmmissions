#!/bin/bash
# Valid alternative: drop the import and let the parent template read the subchart's value from its own values map.
set -euo pipefail
source "$HM_LIB"

"$HM_PYTHON" - <<'PY'
p = "invoicing/templates/deployment.yaml"
s = open(p).read().replace('.Values.db.port', '(index .Values "pg-lite" "service" "port")')
open(p, "w").write(s)
PY
helm install invoicing ./invoicing -n "$NS" --wait --timeout 120s
