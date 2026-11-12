#!/bin/bash
# Valid alternative: a rollback re-applies a stored manifest and re-creates what is missing.
set -euo pipefail
source "$HM_LIB"

helm rollback sms-gateway 1 -n "$NS" --wait --timeout 90s
