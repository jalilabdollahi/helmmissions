#!/bin/bash
# Half a fix: unlock with a rollback, but never redo the 1.1 upgrade. The release is healthy on 1.0.
set -euo pipefail
source "$HM_LIB"

helm rollback warehouse-stock 1 -n "$NS" --wait --timeout 90s
