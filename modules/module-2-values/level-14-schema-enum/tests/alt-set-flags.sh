#!/bin/bash
# Valid alternative: keep the file and override the two values at install time.
set -euo pipefail
source "$HM_LIB"

helm install search-api ./search-api -n "$NS" --set replicas=1 --set logLevel=warn --wait --timeout 120s
