#!/bin/bash
# Valid alternative: fix the tag in Chart.yaml in place, refresh the lock and pass the tag explicitly on upgrade.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^      - monitorng$/      - monitoring/' tradedesk/Chart.yaml && rm -f tradedesk/Chart.yaml.bak
helm dependency update ./tradedesk
helm upgrade tradedesk ./tradedesk -n "$NS" --set tags.monitoring=false --wait --timeout 120s
