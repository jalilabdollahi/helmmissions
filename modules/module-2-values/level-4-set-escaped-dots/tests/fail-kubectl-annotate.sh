#!/bin/bash
# Tempting hotfix: annotate the running pods directly.
set -euo pipefail
source "$HM_LIB"

kubectl annotate pods -n "$NS" -l app.kubernetes.io/instance=telemetry-agent prometheus.io/scrape=true prometheus.io/port=9100 --overwrite
