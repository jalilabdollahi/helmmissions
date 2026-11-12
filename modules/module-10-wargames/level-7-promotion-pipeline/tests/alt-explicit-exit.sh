#!/bin/bash
# Alternative: no `set -e`; the deploy function exits explicitly on failure instead.
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
perl -pi -e 's/^set -euo pipefail\n//' pipeline.sh
perl -pi -e 's/--wait --timeout 30s "\$\{\@:4\}"/--wait --timeout 30s "\${\@:4}" || exit 1/' pipeline.sh
grep -q '|| exit 1' pipeline.sh
bash pipeline.sh
