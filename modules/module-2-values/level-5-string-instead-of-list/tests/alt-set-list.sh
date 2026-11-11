#!/bin/bash
# Valid alternative: override the string with a list on the command line.
set -euo pipefail
source "$HM_LIB"

helm install cors-gateway ./cors-gateway -n "$NS" --set 'allowedOrigins={https://shop.example}' --wait --timeout 120s
