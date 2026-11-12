#!/bin/bash
# Valid alternative: point the ownership annotations at the new release.
set -euo pipefail
source "$HM_LIB"

kubectl annotate secret db-credentials -n "$NS" --overwrite meta.helm.sh/release-name=storefront meta.helm.sh/release-namespace="$NS"
if [ "$(hm_helm_major)" -ge 4 ]; then extra=--force-conflicts; else extra=; fi
helm install storefront ./storefront -n "$NS" $extra --wait --timeout 120s
