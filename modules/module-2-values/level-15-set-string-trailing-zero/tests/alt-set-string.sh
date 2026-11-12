#!/bin/bash
set -euo pipefail
source "$HM_LIB"

helm upgrade status-page ./status-page -n "$NS" -f status-page/values.yaml --set-string appVersionLabel=1.10 --wait --timeout 120s
