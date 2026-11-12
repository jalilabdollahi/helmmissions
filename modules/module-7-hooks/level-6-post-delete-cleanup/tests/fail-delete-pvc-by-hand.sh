#!/bin/bash
# Tempting wrong fix: delete the leaked PVC with kubectl. The chart still leaks one on every uninstall.
set -euo pipefail
source "$HM_LIB"

kubectl delete pvc exports-scratch -n "$NS"
