#!/bin/bash
# Tempting wrong fix: roll back to 1.0. The release turns green but the 1.1 feature is lost.
set -euo pipefail
source "$HM_LIB"

helm rollback ledger-sync 1 -n "$NS" --wait --timeout 90s
