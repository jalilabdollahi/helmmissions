#!/bin/bash
# Writes .helmignore and installs from the directory - no dist/ archive is produced.
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/reports/.helmignore" "$SANDBOX/reports/.helmignore"
helm install reports ./reports -n "$NS" --wait --timeout 120s
