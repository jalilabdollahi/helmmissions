#!/bin/bash
# Tempting wrong fix: scale the Deployment back up by hand (the HPA would do it anyway) - the chart still resets it.
set -euo pipefail
source "$HM_LIB"

kubectl scale deployment/thumbnail-svc -n "$NS" --replicas=5
