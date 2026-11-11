#!/bin/bash
# Valid alternative: keep the condition as written and rename the values key to match it.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^  enabled: false/  enable: false/' helpdesk/values.yaml && rm -f helpdesk/values.yaml.bak
helm upgrade helpdesk ./helpdesk -n "$NS" --wait --timeout 120s
