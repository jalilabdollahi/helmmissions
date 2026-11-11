#!/bin/bash
# Tempting wrong fix: roll back to revision 1 - it was pruned, the command fails and nothing changes.
set -euo pipefail
source "$HM_LIB"

helm rollback geo-lookup 1 -n "$NS" --wait --timeout 60s || true
