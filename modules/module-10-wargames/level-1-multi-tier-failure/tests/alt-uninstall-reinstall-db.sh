#!/bin/bash
# Alternative: remove the failed db release and install it again from the corrected chart.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
helm uninstall ledger-db -n "$NS" >/dev/null
helm install ledger-db ./ledger-db -n "$NS" --wait --timeout 90s
helm upgrade ledger-api ./ledger-api -n "$NS" --wait --timeout 90s
helm upgrade ledger-web ./ledger-web -n "$NS" --wait --timeout 90s
