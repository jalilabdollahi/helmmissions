#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
# The failed first install left a release behind; reinstall from a clean slate.
helm uninstall ledger-api -n "$NS" --wait >/dev/null
helm install ledger-api ./ledger-api -n "$NS" --wait --timeout 90s
