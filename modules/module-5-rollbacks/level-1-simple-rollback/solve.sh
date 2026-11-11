#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm history quotes-api -n "$NS"
helm rollback quotes-api 1 -n "$NS" --wait --timeout 90s
