#!/bin/bash
# Valid alternative: a caret range on 1.x resolves to the newest 1.2.x as well.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/"^2.0.0"/"^1.2.0"/' searchdesk/Chart.yaml && rm -f searchdesk/Chart.yaml.bak
helm dependency update ./searchdesk
helm install searchdesk ./searchdesk -n "$NS" --wait --timeout 120s
