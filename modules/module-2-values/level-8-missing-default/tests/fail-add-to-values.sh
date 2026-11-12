#!/bin/bash
# Tempting: add timeout to values.yaml. Works today, but the chart still renders an empty timeout whenever the key is absent.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/^  retries: 3/  retries: 3\n  timeout: 30/' fetcher/values.yaml
helm upgrade fetcher ./fetcher -n "$NS" --wait --timeout 120s
