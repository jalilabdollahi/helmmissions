#!/bin/bash
# Valid alternative: delete the Job when it succeeds AND when it fails, so nothing is ever left behind.
set -euo pipefail
source "$HM_LIB"

sed -i.bak 's/"helm.sh\/hook-delete-policy": .*/"helm.sh\/hook-delete-policy": hook-succeeded,hook-failed/' "$SANDBOX/tax-engine/templates/rate-check-job.yaml"
rm -f "$SANDBOX/tax-engine/templates/rate-check-job.yaml.bak"
kubectl delete job tax-engine-rate-check -n "$NS" --ignore-not-found >/dev/null
helm upgrade tax-engine ./tax-engine -n "$NS" --wait --timeout 90s
