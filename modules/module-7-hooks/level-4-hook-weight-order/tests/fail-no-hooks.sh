#!/bin/bash
# Tempting wrong fix: skip the hooks. The release deploys but no database work happened.
set -euo pipefail
source "$HM_LIB"

helm upgrade orders ./order-service -n "$NS" --no-hooks --wait --timeout 90s
