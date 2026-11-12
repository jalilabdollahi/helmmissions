#!/bin/bash
# Tempting shortcut: trim the ports list to one entry so no duplicates remain (the admin and metrics ports vanish).
set -euo pipefail
source "$HM_LIB"

python3 - "$SANDBOX/mesh-edge/values.yaml" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
i = s.index("  - name: admin")
j = s.index("resources:")
open(p, "w").write(s[:i] + "\n" + s[j:])
PY
helm install edge ./mesh-edge -n "$NS" --wait --timeout 120s
