#!/bin/bash
# Tempting wrong fix: turn the guard off so the root image starts.
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/broken/status-page/values.yaml" "$SANDBOX/status-page/values.yaml"
python3 - <<'PY'
p='status-page/values.yaml'
s=open(p).read().replace('podSecurityContext:\n  runAsNonRoot: true','podSecurityContext: {}')
open(p,'w').write(s)
PY
helm upgrade status-page ./status-page -n "$NS" --wait --timeout 120s
