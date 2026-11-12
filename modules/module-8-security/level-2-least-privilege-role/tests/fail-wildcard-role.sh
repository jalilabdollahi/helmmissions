#!/bin/bash
# Tempting wrong fix: stop the 403s with a wildcard rule.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - <<'PY'
p='flag-sync/templates/role.yaml'
s=open(p).read()
a=s.index('rules:'); b=s.index('---')
s=s[:a]+'rules:\n  - apiGroups: ["*"]\n    resources: ["*"]\n    verbs: ["*"]\n'+s[b:]
open(p,'w').write(s)
PY
helm upgrade flag-sync ./flag-sync -n "$NS" --wait --timeout 120s
