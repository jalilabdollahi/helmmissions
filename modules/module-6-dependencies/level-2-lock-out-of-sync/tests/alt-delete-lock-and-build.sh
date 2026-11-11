#!/bin/bash
# Valid alternative: remove the stale lock; `build` then resolves from Chart.yaml and writes a fresh lock.
set -euo pipefail
source "$HM_LIB"

rm ledger/Chart.lock
helm dependency build ./ledger
helm upgrade ledger ./ledger -n "$NS" --wait --timeout 120s
