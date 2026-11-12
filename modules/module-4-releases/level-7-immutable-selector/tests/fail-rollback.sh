#!/bin/bash
# Wrong fix: roll back to 1.0 — the release is healthy again but the new labels never ship.
set -euo pipefail
source "$HM_LIB"

helm rollback catalog-search 1 -n "$NS" --wait --timeout 90s
