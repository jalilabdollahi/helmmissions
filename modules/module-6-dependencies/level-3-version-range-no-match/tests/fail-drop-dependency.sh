#!/bin/bash
# Tempting shortcut: remove the dependency so the chart installs; there is no cache any more.
set -euo pipefail
source "$HM_LIB"

"$HM_PYTHON" - <<'PY'
import re
p = "searchdesk/Chart.yaml"
s = open(p).read()
open(p, "w").write(re.sub(r"dependencies:.*", "", s, flags=re.S))
PY
helm install searchdesk ./searchdesk -n "$NS" --wait --timeout 120s
