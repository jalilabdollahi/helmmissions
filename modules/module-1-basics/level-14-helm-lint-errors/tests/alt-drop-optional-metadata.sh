#!/bin/bash
# Valid: drop the optional, broken metadata (sources/maintainers) instead of repairing it.
set -euo pipefail
source "$HM_LIB"

cat >"$SANDBOX/newsletter/Chart.yaml" <<'YAML'
apiVersion: v2
name: newsletter
description: Signup page and settings for the weekly newsletter
type: application
version: 2.3.0
appVersion: "2.3"
home: https://newsletter.helmissions.example
YAML
helm lint --strict ./newsletter
helm install newsletter ./newsletter -n "$NS" --wait --timeout 120s
