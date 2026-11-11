#!/bin/bash
# Tempting non-fix: keep upgrading the unchanged chart ("it will settle") - it rotates the password again.
set -euo pipefail
source "$HM_LIB"

helm upgrade ledgerdb ./ledger-db -n "$NS" --wait --timeout 120s
