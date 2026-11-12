#!/bin/bash
# Valid alternative: the narrowest possible grant, just `list` on configmaps.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - <<'PY'
p='flag-sync/templates/role.yaml'
s=open(p).read()
old='verbs: ["get", "list", "watch"]'
i=s.index(old)+len(old)
s=s[:i]+s[i:].replace(old,'verbs: ["list"]',1)
open(p,'w').write(s)
PY
helm upgrade flag-sync ./flag-sync -n "$NS" --wait --timeout 120s
