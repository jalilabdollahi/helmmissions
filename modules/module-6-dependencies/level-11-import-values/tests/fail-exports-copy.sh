#!/bin/bash
# Wrong fix: add a separate exports value (a copy of the number) in the child. It works until somebody changes
# service.port, then the two drift apart.
set -euo pipefail
source "$HM_LIB"

printf 'exports:\n  connection:\n    port: 5432\n' >> pg-lite/values.yaml
"$HM_PYTHON" - <<'PY'
p = "invoicing/Chart.yaml"
s = open(p).read().replace("      - child: service.port\n        parent: db.port\n", "      - child: exports.connection\n        parent: db\n")
open(p, "w").write(s)
PY
sed -i.bak 's/^db: {}/db: {}/' invoicing/values.yaml && rm -f invoicing/values.yaml.bak
helm dependency update ./invoicing
helm install invoicing ./invoicing -n "$NS" --wait --timeout 120s
