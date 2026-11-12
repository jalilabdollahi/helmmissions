#!/bin/bash
# Valid alternative: leave the policy alone and relabel the frontend pods so they match it.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cp "$LEVEL_DIR/broken/shopfront/templates/networkpolicy.yaml" shopfront/templates/networkpolicy.yaml
python3 - <<'PY'
p='shopfront/templates/frontend.yaml'
s=open(p).read()
i=s.index('  template:')
s=s[:i]+s[i:].replace('app.kubernetes.io/component: frontend','app.kubernetes.io/component: web')
open(p,'w').write(s)
PY
helm upgrade shopfront ./shopfront -n "$NS" --wait --timeout 120s
