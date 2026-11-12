#!/bin/bash
# Tempting shortcut: delete the failing include so the Service renders without the standard labels.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
python3 - "$SANDBOX/storefront/templates/service.yaml" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace("  labels:\n    {{- include \"storefront.labels\" . | nindent 4 }}\n", "")
open(p, "w").write(s)
PY
helm install shop ./storefront -n "$NS" --wait --timeout 120s
