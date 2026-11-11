#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Revision 1: the old chart (0.1.0) that is already serving orders.
helm install orders "$LEVEL_DIR/assets/orders-0.1.0" -n "$NS" --wait --timeout 120s >/dev/null
[ "$(hm_release_chart orders)" = "orders-0.1.0" ] || { echo "setup: expected orders-0.1.0"; exit 1; }

# The new chart in the workspace cannot be installed under the same name.
if helm install orders "$SANDBOX/orders" -n "$NS" >"$HM_TMP/install.txt" 2>&1; then
  echo "setup: second install succeeded - scenario is not broken"; exit 1
fi
grep -q "name that is still in use" "$HM_TMP/install.txt" || { cat "$HM_TMP/install.txt"; exit 1; }
