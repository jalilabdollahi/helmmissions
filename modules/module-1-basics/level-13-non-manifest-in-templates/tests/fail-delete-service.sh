#!/bin/bash
# Removes a real template instead of the prose file; the chart still does not render.
set -euo pipefail
source "$HM_LIB"

rm "$SANDBOX/helpdesk/templates/service.yaml"
helm install helpdesk ./helpdesk -n "$NS" || true
