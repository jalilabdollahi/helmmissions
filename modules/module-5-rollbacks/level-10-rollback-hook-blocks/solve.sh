#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm rollback settlement-batch 1 -n "$NS" --no-hooks --wait --timeout 90s
