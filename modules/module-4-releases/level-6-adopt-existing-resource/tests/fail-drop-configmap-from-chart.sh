#!/bin/bash
# Wrong fix: change the chart so it no longer ships the ConfigMap. Release deploys, but desk-settings is
# not managed by Helm and still holds the hand-made values.
set -euo pipefail
source "$HM_LIB"

rm "$SANDBOX/support-desk/templates/configmap.yaml"
helm install support-desk ./support-desk -n "$NS" --wait --timeout 90s
