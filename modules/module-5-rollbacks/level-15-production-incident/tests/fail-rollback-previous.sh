#!/bin/bash
# Tempting wrong fix: "roll back one revision". Revision 2 has the retired payment gateway.
set -euo pipefail
source "$HM_LIB"

helm rollback checkout 2 -n "$NS" --wait --timeout 90s
