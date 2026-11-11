#!/bin/bash
# Another valid fix: give the chart a default cache block in values.yaml.
set -euo pipefail
source "$HM_LIB"

cat >> profile-svc/values.yaml <<'YAML'

cache:
  redis:
    host: ""
    port: 6379
YAML
helm install profile-svc ./profile-svc -n "$NS" -f values-staging.yaml --wait --timeout 120s
