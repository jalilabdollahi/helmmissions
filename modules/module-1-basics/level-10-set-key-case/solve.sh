#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade billing ./billing -n "$NS" --set replicaCount=4 --wait --timeout 120s
