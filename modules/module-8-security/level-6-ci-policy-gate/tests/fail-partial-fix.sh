#!/bin/bash
# Wrong fix: only the image tag is pinned; limits and probes are still missing.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/tag: latest/tag: 1.27-alpine/' report-worker/values.yaml && rm -f report-worker/values.yaml.bak
helm upgrade --install report-worker ./report-worker -n "$NS" --wait --timeout 120s
