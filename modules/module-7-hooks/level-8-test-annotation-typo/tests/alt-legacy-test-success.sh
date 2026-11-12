#!/bin/bash
# Valid alternative: the legacy annotation name `test-success` is still understood.
set -euo pipefail
source "$HM_LIB"

python3 - "$SANDBOX/inventory-search/templates/tests/search-test.yaml" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
open(p, "w").write(s.replace('"helm.sh/hook": tests', '"helm.sh/hook": test-success'))
PY
helm upgrade search ./inventory-search -n "$NS" --wait --timeout 90s
helm test search -n "$NS" --timeout 60s
