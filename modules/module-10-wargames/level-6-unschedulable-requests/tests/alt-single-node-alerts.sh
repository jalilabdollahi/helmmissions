#!/bin/bash
# Alternative: fix the units, drop the node selector and switch off the hard anti-affinity entirely (none).
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
perl -pi -e 's/mode: preferred/mode: none/' values/alerts.yaml
bash release.sh
