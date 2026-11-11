#!/bin/bash
# Valid alternative: convert the tabs mechanically (one tab -> two spaces).
set -euo pipefail
source "$HM_LIB"

"$HM_PYTHON" - <<'PY'
p = "audit-log/values.yaml"
t = open(p).read().replace("\t", "  ")
open(p, "w").write(t)
PY
helm install audit-log ./audit-log -n "$NS" --wait --timeout 120s
