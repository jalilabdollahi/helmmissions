#!/bin/bash
# Wrong fix: scope a `region` key to each subchart. They read global.region, so nothing changes.
set -euo pipefail
source "$HM_LIB"

helm upgrade telemetry ./telemetry -n "$NS" --set collector.region=eu-west-1 --set exporter.region=eu-west-1 --wait --timeout 120s
