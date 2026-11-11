#!/bin/bash
# Works, but there is no values file in the workspace for review.
set -euo pipefail
source "$HM_LIB"

helm install node-probe vendor/node-probe-0.4.2.tgz -n "$NS" --set telemetry.servicePort=9100 --wait --timeout 120s
