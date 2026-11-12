#!/bin/bash
# Partial fix: roll back to the good revision but leave the manual hotfix env and the bad values-prod.yaml in place.
set -euo pipefail
source "$HM_LIB"

helm rollback checkout 1 -n "$NS" --wait --timeout 90s
