#!/bin/bash
# Wrong fix: remove the subchart from Chart.yaml. It disappears, but the on/off switch is gone for good.
set -euo pipefail
source "$HM_LIB"

"$HM_PYTHON" - <<'PY'
import re
p = "helpdesk/Chart.yaml"
s = open(p).read()
open(p, "w").write(re.sub(r"dependencies:.*", "", s, flags=re.S))
PY
rm -rf helpdesk/charts helpdesk/Chart.lock
helm upgrade helpdesk ./helpdesk -n "$NS" --wait --timeout 120s
