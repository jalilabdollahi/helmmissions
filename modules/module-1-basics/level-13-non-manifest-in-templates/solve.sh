#!/bin/bash
set -euo pipefail
source "$HM_LIB"

mv "$SANDBOX/helpdesk/templates/usage-notes.yaml" "$SANDBOX/helpdesk/templates/NOTES.txt"
helm install helpdesk ./helpdesk -n "$NS" --wait --timeout 120s
