#!/bin/bash
# Wrong fix: keep the root-based image and just pick a UID. nginx cannot bind port 80 or write its root-owned dirs.
set -euo pipefail
source "$HM_LIB"

python3 - <<'PY'
p='status-page/values.yaml'
s=open(p).read().replace('  runAsNonRoot: true','  runAsNonRoot: true\n  runAsUser: 1000')
open(p,'w').write(s)
PY
helm upgrade status-page ./status-page -n "$NS" --wait --timeout 40s || true
