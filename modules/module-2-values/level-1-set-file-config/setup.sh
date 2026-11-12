#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The colleague's command: --set takes the literal string, not the file behind it.
helm install landing "$SANDBOX/landing" -n "$NS" --set siteConfig=./site.conf >/dev/null
cm="$(kubectl get configmap landing-nginx -n "$NS" -o jsonpath='{.data.default\.conf}')"
[ "$cm" = "./site.conf" ] || { echo "setup: ConfigMap does not hold the literal path"; exit 1; }
[ "$(hm_release_status landing)" = deployed ] || { echo "setup: release not deployed"; exit 1; }
