#!/bin/bash
# Alternative: keep an ignore rule but make it specific to local experiments only.
set -euo pipefail
source "$HM_LIB"

cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"
printf 'local-*.conf\n' >> "$SANDBOX/legacy-site/.helmignore"
helm upgrade site ./legacy-site -n "$NS" --wait --timeout 120s
