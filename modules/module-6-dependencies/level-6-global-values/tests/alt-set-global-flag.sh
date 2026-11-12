#!/bin/bash
# Valid alternative: provide the global on the command line.
set -euo pipefail
source "$HM_LIB"

helm upgrade telemetry ./telemetry -n "$NS" --set global.region=eu-west-1 --wait --timeout 120s
