#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Yesterday's deploy: someone tested against a local mock and left the override in place.
helm install weather-widget "$SANDBOX/weather-widget" -n "$NS" \
  --set config.apiUrl=http://localhost:9999 --wait --timeout 120s >/dev/null
url="$(hm_jsonpath configmap/weather-widget-config '{.data.config\.json}' | jq -r .apiUrl)"
[ "$url" = "http://localhost:9999" ] || { echo "setup: override not applied ($url)"; exit 1; }
