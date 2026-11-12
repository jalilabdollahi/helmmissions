#!/bin/bash
# Valid: a hand-written .helmignore with different (but sufficient) patterns.
set -euo pipefail
source "$HM_LIB"

printf '*.env\n*.bak\ntmp\n' >"$SANDBOX/reports/.helmignore"
helm package ./reports -d dist
helm install reports dist/reports-1.1.0.tgz -n "$NS" --wait --timeout 120s
