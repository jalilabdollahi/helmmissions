#!/bin/bash
# Partial fix: constraint corrected and lock written, but the release was never installed.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
helm dependency update ./searchdesk
