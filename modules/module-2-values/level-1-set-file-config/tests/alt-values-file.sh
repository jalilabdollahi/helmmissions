#!/bin/bash
# Another valid fix: put the server block into a values file and use -f.
set -euo pipefail
source "$HM_LIB"

{ echo "siteConfig: |"; sed 's/^/  /' site.conf; } > values-landing.yaml
helm upgrade landing ./landing -n "$NS" -f values-landing.yaml --wait --timeout 120s
