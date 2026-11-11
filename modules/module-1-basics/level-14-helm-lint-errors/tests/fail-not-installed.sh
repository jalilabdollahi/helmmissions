#!/bin/bash
# Lint is green but the release was never installed.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/newsletter/." "$SANDBOX/newsletter/"
