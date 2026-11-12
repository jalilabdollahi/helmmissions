#!/bin/bash
# Tempting wrong fix: create the Secret with kubectl before installing. Helm then refuses to adopt it.
set -euo pipefail
source "$HM_LIB"

kubectl create secret generic payroll-db -n "$NS" --from-literal=DB_ROLE=payroll_app --from-literal=DB_PASSWORD=by-hand
helm uninstall payroll -n "$NS" --wait >/dev/null
helm install payroll ./payroll-api -n "$NS" --timeout 90s || true
