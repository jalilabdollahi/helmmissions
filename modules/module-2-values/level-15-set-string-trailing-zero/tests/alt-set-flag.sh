#!/bin/bash
# `--set` keeps 1.10 as a string (it only converts integers, booleans and null), so it also overrides the float.
set -euo pipefail
source "$HM_LIB"

helm upgrade status-page ./status-page -n "$NS" -f status-page/values.yaml --set appVersionLabel=1.10 --wait --timeout 120s
