#!/bin/bash
# Valid alternative path on Helm 4: --take-ownership alone hits a field conflict and leaves a failed
# revision; retrying as an upgrade with --force-conflicts finishes the job.
set -euo pipefail
source "$HM_LIB"

if [ "$(hm_helm_major)" -ge 4 ]; then
  helm install support-desk ./support-desk -n "$NS" --take-ownership >/dev/null 2>&1 || true
  helm upgrade support-desk ./support-desk -n "$NS" --take-ownership --force-conflicts --wait --timeout 120s
else
  helm install support-desk ./support-desk -n "$NS" --take-ownership --wait --timeout 120s
fi
