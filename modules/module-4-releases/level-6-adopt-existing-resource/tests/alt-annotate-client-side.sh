#!/bin/bash
# Valid alternative: add the ownership metadata by hand (the classic adoption recipe).
# On Helm 4 the install must not use server-side apply, otherwise kubectl's field ownership conflicts.
set -euo pipefail
source "$HM_LIB"

kubectl label configmap desk-settings -n "$NS" app.kubernetes.io/managed-by=Helm --overwrite
kubectl annotate configmap desk-settings -n "$NS" meta.helm.sh/release-name=support-desk meta.helm.sh/release-namespace="$NS" --overwrite
if [ "$(hm_helm_major)" -ge 4 ]; then extra=--server-side=false; else extra=; fi
helm install support-desk ./support-desk -n "$NS" $extra --wait --timeout 120s
