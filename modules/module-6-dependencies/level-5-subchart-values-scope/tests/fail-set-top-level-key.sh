#!/bin/bash
# Wrong fix: pass the settings at the top level of the parent — they are parent values, the subchart never sees them.
set -euo pipefail
source "$HM_LIB"

helm upgrade newsroom ./newsroom -n "$NS" --set replicaCount=3 --set maxWidth=800 --set quality=70 --wait --timeout 120s
