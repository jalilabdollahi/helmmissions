#!/bin/bash
# Wrong fix: "just roll back one" - revision 5's readiness probe never passes.
set -euo pipefail
source "$HM_LIB"

helm rollback freight-quote -n "$NS" --timeout 20s || true
