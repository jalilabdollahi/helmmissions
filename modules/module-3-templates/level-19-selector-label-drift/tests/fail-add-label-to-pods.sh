#!/bin/bash
# Tempting workaround: add the hand-written label to the pods so the old selector matches.
set -euo pipefail
source "$HM_LIB"

python3 - "$SANDBOX/payments/templates/deployment.yaml" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace('      labels:\n        {{- include "payments.labels" . | nindent 8 }}', '      labels:\n        app: payments\n        {{- include "payments.labels" . | nindent 8 }}')
open(p, "w").write(s)
PY
helm upgrade payments ./payments -n "$NS" --wait --timeout 120s
