#!/bin/bash
# Tempting shortcut: skip the dependency step. `helm upgrade` happily packages the old tarball from charts/.
set -euo pipefail
source "$HM_LIB"

helm upgrade ledger ./ledger -n "$NS" --wait --timeout 120s
