#!/bin/bash
# Alternative: keep --reuse-values, but remove the polluted release first so nothing is reused (loses history).
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
perl -pi -e 's/--reset-values/--reuse-values/' deploy.sh
helm uninstall invoice -n "$NS" >/dev/null
bash deploy.sh prod
