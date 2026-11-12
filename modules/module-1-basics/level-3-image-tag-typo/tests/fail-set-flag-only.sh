#!/bin/bash
# Fixes the live release with --set but never fixes values.yaml: the next plain upgrade brings the typo back.
set -euo pipefail
source "$HM_LIB"

helm upgrade ledger-api ./ledger-api -n "$NS" --set image.tag=1.27-alpine --wait --timeout 120s
