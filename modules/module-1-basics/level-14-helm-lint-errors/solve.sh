#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/newsletter/." "$SANDBOX/newsletter/"
bash ci/lint.sh
helm install newsletter ./newsletter -n "$NS" --wait --timeout 120s
