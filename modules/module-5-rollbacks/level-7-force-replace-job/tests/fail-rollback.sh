#!/bin/bash
# Wrong fix: roll back to revision 1 - the release is deployed again but the new dataset is not seeded.
set -euo pipefail
source "$HM_LIB"

helm rollback catalog 1 -n "$NS" --wait --timeout 90s
