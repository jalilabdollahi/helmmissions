#!/bin/bash
# Valid alternative: fix the condition path in Chart.yaml and upgrade with an explicit --set as well.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/condition: search.enable$/condition: search.enabled/' helpdesk/Chart.yaml && rm -f helpdesk/Chart.yaml.bak
helm dependency update ./helpdesk
helm upgrade helpdesk ./helpdesk -n "$NS" --set search.enabled=false --wait --timeout 120s
