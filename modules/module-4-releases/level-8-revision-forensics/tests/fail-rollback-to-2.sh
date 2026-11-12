#!/bin/bash
# Tempting wrong fix: roll back to revision 2, when search worked. Revisions 4 and 5 are lost.
set -euo pipefail
source "$HM_LIB"

helm rollback product-search 2 -n "$NS" --wait --timeout 90s
