#!/bin/bash
# Wrong fix: roll back to revision 1 - traffic is back on blue but green is gone (scaled to 0), nothing left to debug.
set -euo pipefail
source "$HM_LIB"

helm rollback ticket-booking 1 -n "$NS" --wait --timeout 90s
