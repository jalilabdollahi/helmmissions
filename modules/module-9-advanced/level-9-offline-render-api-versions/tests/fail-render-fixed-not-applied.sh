#!/bin/bash
# Partial fix: render.sh fixed and re-run, but the new output is never applied.
set -euo pipefail
source "$HM_LIB"

cp "$LEVEL_DIR/solution/render.sh" render.sh
chmod +x render.sh
./render.sh
