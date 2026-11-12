#!/bin/bash
# Gives up on the target namespace and installs into the existing one.
set -euo pipefail
source "$HM_LIB"

helm install metrics-proxy ./metrics-proxy -n "$NS" --wait --timeout 120s
