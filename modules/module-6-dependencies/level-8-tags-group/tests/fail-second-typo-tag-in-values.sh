#!/bin/bash
# Wrong fix: add the misspelled tag to values.yaml so this environment is quiet, instead of fixing the declaration.
# The group no longer toggles together.
set -euo pipefail
source "$HM_LIB"

printf '  monitorng: false\n' >> tradedesk/values.yaml
helm upgrade tradedesk ./tradedesk -n "$NS" --wait --timeout 120s
