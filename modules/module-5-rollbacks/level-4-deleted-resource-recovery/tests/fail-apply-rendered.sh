#!/bin/bash
# Wrong fix: render the chart and kubectl-apply only the Service - the object has no Helm ownership annotations.
set -euo pipefail
source "$HM_LIB"

helm template sms-gateway ./sms-gateway -n "$NS" --set carrier=contoso -s templates/service.yaml | kubectl apply -n "$NS" -f -
