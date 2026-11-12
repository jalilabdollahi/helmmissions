#!/bin/bash
# Alternative: split the two objects into two template files instead of adding a separator.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - "$SANDBOX/status-page/templates" <<'PY'
import sys, os
d = sys.argv[1]
s = open(os.path.join(d, "app.yaml")).read()
dep, svc = s.split("\n---\n")
os.remove(os.path.join(d, "app.yaml"))
open(os.path.join(d, "deployment.yaml"), "w").write(dep + "\n")
open(os.path.join(d, "service.yaml"), "w").write(svc)
PY
helm upgrade status ./status-page -n "$NS" --wait --timeout 120s
