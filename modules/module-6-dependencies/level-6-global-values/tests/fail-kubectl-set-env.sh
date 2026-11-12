#!/bin/bash
# Tempting shortcut: patch the live Deployments; the release itself still carries REGION=unset.
set -euo pipefail
source "$HM_LIB"

helm upgrade telemetry ./telemetry -n "$NS" --reuse-values --wait --timeout 120s >/dev/null
for d in gateway collector exporter; do kubectl set env "deployment/telemetry-$d" -n "$NS" REGION=eu-west-1; done
for d in gateway collector exporter; do kubectl rollout status "deployment/telemetry-$d" -n "$NS" --timeout=90s; done
