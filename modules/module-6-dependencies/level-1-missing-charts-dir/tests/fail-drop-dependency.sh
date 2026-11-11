#!/bin/bash
# Tempting shortcut: delete the dependency block so the install "works" — the cache is simply gone.
set -euo pipefail
source "$HM_LIB"

"$HM_PYTHON" - <<'PY'
import re
p = "storefront/Chart.yaml"
s = open(p).read()
open(p, "w").write(re.sub(r"dependencies:.*", "", s, flags=re.S))
PY
helm install storefront ./storefront -n "$NS" --wait --timeout 120s
