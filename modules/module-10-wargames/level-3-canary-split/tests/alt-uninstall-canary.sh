#!/bin/bash
# Alternative: scale stable and reinstall the failed canary release from scratch.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
helm uninstall catalog-canary -n "$NS" >/dev/null
bash release.sh
