#!/bin/bash
# Fixes only what plain `helm lint` reports as ERROR; the warnings keep the --strict gate red.
set -euo pipefail
source "$HM_LIB"

cat >"$SANDBOX/newsletter/Chart.yaml" <<'YAML'
apiVersion: v2
name: Newsletter
description: Signup page and settings for the weekly newsletter
type: application
version: "1.0"
appVersion: "2.3"
home: https://newsletter.helmissions.example
YAML
helm lint "$SANDBOX/newsletter"
helm install newsletter ./newsletter -n "$NS" || true
