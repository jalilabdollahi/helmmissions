#!/bin/bash
# Right key, but --reuse-values drags the stray `replicacount` along.
set -euo pipefail
source "$HM_LIB"

helm upgrade billing ./billing -n "$NS" --reuse-values --set replicaCount=4 --wait --timeout 120s
