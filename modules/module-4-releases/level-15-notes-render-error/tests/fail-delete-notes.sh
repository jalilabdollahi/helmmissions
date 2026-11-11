#!/bin/bash
# Tempting wrong fix: delete NOTES.txt. The install succeeds, but the post-install guidance is gone.
set -euo pipefail
source "$HM_LIB"

rm "$SANDBOX/status-page/templates/NOTES.txt"
helm install status-page ./status-page -n "$NS" --wait --timeout 90s
