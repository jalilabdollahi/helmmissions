#!/bin/bash
# Valid alternative: the hand-made object has no value worth keeping — delete it, let Helm create it.
set -euo pipefail
source "$HM_LIB"

kubectl delete configmap desk-settings -n "$NS"
helm install support-desk ./support-desk -n "$NS" --wait --timeout 120s
