#!/bin/bash
# Tempting wrong fix: correct the annotation in the file and run helm test. The release still has no test hook.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm test search -n "$NS" --timeout 60s
