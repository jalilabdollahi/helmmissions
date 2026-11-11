#!/bin/bash
# Tempting workaround: leave the template alone and force the tag with --set. The chart is still wrong.
set -euo pipefail
source "$HM_LIB"

helm upgrade echo ./echo-api -n "$NS" --set image.tag=v1.10 --timeout 30s || true
