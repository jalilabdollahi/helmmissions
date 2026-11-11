#!/bin/bash
set -euo pipefail
source "$HM_LIB"

# The team's last release: only tax-tables arrived, pay-calendar never did, and nothing complained.
helm dependency update "$SANDBOX/payroll" >/dev/null 2>&1
helm install payroll "$SANDBOX/payroll" -n "$NS" --wait --timeout 120s >/dev/null
hm_assert_status payroll deployed
kubectl get deployment payroll-tax-tables -n "$NS" >/dev/null 2>&1 || { echo "setup: tax-tables should be running"; exit 1; }
! kubectl get deployment payroll-pay-calendar -n "$NS" >/dev/null 2>&1 || { echo "setup: pay-calendar should be missing"; exit 1; }
