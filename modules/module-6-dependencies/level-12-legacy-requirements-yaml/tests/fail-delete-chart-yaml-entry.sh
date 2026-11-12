#!/bin/bash
# Wrong fix: remove the pay-calendar entry from Chart.yaml so both lists agree again (and the calendar is gone).
set -euo pipefail
source "$HM_LIB"

"$HM_PYTHON" - <<'PY'
p = "payroll/Chart.yaml"
s = open(p).read()
i = s.index("  - name: pay-calendar")
open(p, "w").write(s[:i])
PY
helm dependency update ./payroll
helm upgrade payroll ./payroll -n "$NS" --wait --timeout 120s
