#!/bin/bash
# Valid alternative: keep the helper, pass a short fullnameOverride in the release values.
set -euo pipefail
source "$HM_LIB"

REL=customer-notification-dispatcher-production-eu
helm upgrade "$REL" ./notification-dispatcher -n "$NS" --set fullnameOverride=notification-dispatcher-eu --wait --timeout 120s \
  || helm install "$REL" ./notification-dispatcher -n "$NS" --set fullnameOverride=notification-dispatcher-eu --wait --timeout 120s
