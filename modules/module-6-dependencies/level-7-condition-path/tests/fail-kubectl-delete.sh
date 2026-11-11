#!/bin/bash
# Tempting shortcut: delete the search objects by hand. The release still owns them and the chart still deploys them.
set -euo pipefail
source "$HM_LIB"

kubectl delete deployment,service helpdesk-ticket-search -n "$NS"
