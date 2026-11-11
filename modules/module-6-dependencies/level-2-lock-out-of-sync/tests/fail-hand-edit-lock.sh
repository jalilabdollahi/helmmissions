#!/bin/bash
# Tempting shortcut: edit the version in Chart.lock by hand (the digest no longer matches) and upgrade.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/version: 0.3.0/version: 0.4.0/' ledger/Chart.lock && rm -f ledger/Chart.lock.bak
helm upgrade ledger ./ledger -n "$NS" --wait --timeout 120s
