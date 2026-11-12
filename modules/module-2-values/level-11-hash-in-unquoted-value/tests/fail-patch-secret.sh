#!/bin/bash
# Tempting hotfix: patch the Secret with kubectl and restart. Helm's own manifest still carries the truncated value.
set -euo pipefail
source "$HM_LIB"

kubectl patch secret ledger-api-db -n "$NS" -p "{\"data\":{\"DB_PASSWORD\":\"$(printf '%s' 'Harbor Light #2024' | base64)\"}}"
kubectl delete pod -n "$NS" -l app.kubernetes.io/instance=ledger-api --now
kubectl rollout status deployment/ledger-api -n "$NS" --timeout=90s
