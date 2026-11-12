#!/bin/bash
# Wrong fix: aliases that don't match the `primary:` / `replica:` blocks in values.yaml —
# both instances run with the subchart defaults and under the wrong names.
set -euo pipefail
source "$HM_LIB"

"$HM_PYTHON" - <<'PY'
p = "inventory/Chart.yaml"
s = open(p).read()
parts = s.split("  - name: kvstore\n")
open(p, "w").write(parts[0] + "  - name: kvstore\n    alias: kv1\n" + parts[1] + "  - name: kvstore\n    alias: kv2\n" + parts[2])
PY
helm dependency update ./inventory
helm install inventory ./inventory -n "$NS" --wait --timeout 120s
