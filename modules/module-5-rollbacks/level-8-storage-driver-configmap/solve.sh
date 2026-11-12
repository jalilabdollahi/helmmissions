#!/bin/bash
set -euo pipefail
source "$HM_LIB"

source ci/pipeline.env
helm history audit-gateway -n "$NS"
helm rollback audit-gateway 1 -n "$NS" --wait --timeout 90s
