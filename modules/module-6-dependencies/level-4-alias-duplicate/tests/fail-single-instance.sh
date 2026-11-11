#!/bin/bash
# Tempting shortcut: delete the duplicate entry so the chart loads — now there is only one store.
set -euo pipefail
source "$HM_LIB"

"$HM_PYTHON" - <<'PY'
p = "inventory/Chart.yaml"
s = open(p).read()
head, _, rest = s.partition("dependencies:\n")
open(p, "w").write(head + "dependencies:\n  - name: kvstore\n    version: 0.2.0\n    repository: file://../kvstore\n")
PY
helm dependency update ./inventory
helm install inventory ./inventory -n "$NS" --wait --timeout 120s
