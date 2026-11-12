#!/bin/bash
# Tempting wrong fix: go back to the very first revision "because it worked" - insurance doesn't exist there.
set -euo pipefail
source "$HM_LIB"

helm rollback freight-quote 1 -n "$NS" --wait --timeout 120s
