#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade orders ./orders -n "$NS" --wait --timeout 120s
