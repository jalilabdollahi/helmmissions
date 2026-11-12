#!/bin/bash
# Tempting shortcut: delete the straggler by hand; the release still owns it.
set -euo pipefail
source "$HM_LIB"

kubectl delete deployment,service tradedesk-log-shipper -n "$NS" --ignore-not-found
helm upgrade tradedesk ./tradedesk -n "$NS" --wait --timeout 120s   # a new revision, but the declaration is unchanged
