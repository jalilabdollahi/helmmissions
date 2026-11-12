#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/reports/.helmignore" "$SANDBOX/reports/.helmignore"
helm package ./reports -d dist
helm install reports dist/reports-1.1.0.tgz -n "$NS" --wait --timeout 120s
