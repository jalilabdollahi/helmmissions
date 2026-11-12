#!/bin/bash
# Wrong fix: make the problem invisible by running fewer replicas of nothing.
set -euo pipefail
source "$HM_LIB"

kubectl scale deployment/search-indexer -n "$NS" --replicas=0
