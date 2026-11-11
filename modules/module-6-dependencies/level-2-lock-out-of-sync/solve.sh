#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm dependency update ./ledger
helm upgrade ledger ./ledger -n "$NS" --wait --timeout 120s
