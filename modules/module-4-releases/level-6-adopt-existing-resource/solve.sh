#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# Adopt the ConfigMap into the release. On Helm 4 (server-side apply) the chart must also win the
# field-manager conflict with kubectl.
if [ "$(hm_helm_major)" -ge 4 ]; then extra=--force-conflicts; else extra=; fi
helm install support-desk ./support-desk -n "$NS" --take-ownership $extra --wait --timeout 120s
