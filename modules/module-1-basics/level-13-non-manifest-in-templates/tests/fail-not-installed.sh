#!/bin/bash
# Fixes the chart but never installs it.
set -euo pipefail
source "$HM_LIB"

mv "$SANDBOX/helpdesk/templates/usage-notes.yaml" "$SANDBOX/helpdesk/templates/NOTES.txt"
