#!/bin/bash
# Valid but heavier: uninstall and install again without the override.
set -euo pipefail
source "$HM_LIB"

helm uninstall weather-widget -n "$NS"
helm install weather-widget ./weather-widget -n "$NS" --wait --timeout 120s
