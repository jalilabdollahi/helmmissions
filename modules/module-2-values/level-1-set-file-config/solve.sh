#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade landing ./landing -n "$NS" --set-file siteConfig=./site.conf --wait --timeout 120s
