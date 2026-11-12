#!/bin/bash
# Wrong fix: configmaps granted with every verb "to be safe".
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - <<'PY'
p='flag-sync/templates/role.yaml'
s=open(p).read()
old='verbs: ["get", "list", "watch"]'
i=s.index(old)+len(old)
s=s[:i]+s[i:].replace(old,'verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]',1)
open(p,'w').write(s)
PY
helm upgrade flag-sync ./flag-sync -n "$NS" --wait --timeout 120s
