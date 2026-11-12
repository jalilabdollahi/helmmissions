#!/bin/bash
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
# The failed first install is a release; with a pre-install-only hook the clean way is to reinstall.
helm uninstall payroll -n "$NS" --wait >/dev/null
helm install payroll ./payroll-api -n "$NS" --wait --timeout 90s
