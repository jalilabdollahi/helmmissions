#!/bin/bash
# Valid: keep the notes as documentation outside templates/.
set -euo pipefail
source "$HM_LIB"

mkdir -p "$SANDBOX/helpdesk/docs"
mv "$SANDBOX/helpdesk/templates/usage-notes.yaml" "$SANDBOX/helpdesk/docs/usage-notes.md"
helm install helpdesk ./helpdesk -n "$NS" --wait --timeout 120s
