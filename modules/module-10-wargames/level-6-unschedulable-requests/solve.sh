#!/bin/bash
set -euo pipefail
source "$HM_LIB"
cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
cd "$SANDBOX"
bash release.sh
