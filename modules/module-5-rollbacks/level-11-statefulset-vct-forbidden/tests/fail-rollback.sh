#!/bin/bash
# Wrong fix: roll back to revision 1 - release is deployed, but the retention change is lost.
set -euo pipefail
source "$HM_LIB"

helm rollback tsdb 1 -n "$NS" --wait --timeout 120s
