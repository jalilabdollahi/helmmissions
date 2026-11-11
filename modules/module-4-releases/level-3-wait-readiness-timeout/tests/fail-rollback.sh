#!/bin/bash
# Tempting wrong fix: roll back to the last good revision — green, but 2.1 (replicas + probe) is lost.
set -euo pipefail
source "$HM_LIB"

helm rollback docs-portal 1 -n "$NS" --wait --timeout 90s
