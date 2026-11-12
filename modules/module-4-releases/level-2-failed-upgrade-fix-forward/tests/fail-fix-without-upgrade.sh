#!/bin/bash
# The file is fixed but never deployed: the release stays failed.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
