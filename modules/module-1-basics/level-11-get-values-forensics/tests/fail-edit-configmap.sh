#!/bin/bash
# Tempting hotfix: patch the live ConfigMap. The release still has the override.
set -euo pipefail
source "$HM_LIB"

kubectl patch configmap weather-widget-config -n "$NS" --type merge \
  -p '{"data":{"config.json":"{\n  \"apiUrl\": \"https://api.weather.helmissions.example/v1\",\n  \"units\": \"metric\",\n  \"refreshSeconds\": 300\n}\n"}}'
