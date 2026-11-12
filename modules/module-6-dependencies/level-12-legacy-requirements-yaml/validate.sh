#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/payroll"

hm_info "Checking where the chart declares its dependencies..."
for d in tax-tables pay-calendar; do
  hm_yaml_get "$CHART/Chart.yaml" dependencies | jq -e --arg d "$d" 'any(.[]; .name==$d)' >/dev/null \
    || hm_fail "payroll/Chart.yaml does not declare $d"
  hm_yaml_get "$CHART/Chart.lock" dependencies | jq -e --arg d "$d" 'any(.[]; .name==$d)' >/dev/null \
    || hm_fail "Chart.lock has no entry for $d — the dependency set was never re-resolved"
done
[ ! -e "$CHART/requirements.yaml" ] || hm_fail "payroll/requirements.yaml is still there: an apiVersion v2 chart declares its dependencies in Chart.yaml only"
ws="$HM_TMP/ci"
mkdir -p "$ws"
cp -R "$CHART" "$ws/payroll"
cp -R "$SANDBOX/tax-tables" "$SANDBOX/pay-calendar" "$ws/"
helm dependency build "$ws/payroll" >"$HM_TMP/build.txt" 2>&1 || hm_fail "helm dependency build ./payroll fails" "$HM_TMP/build.txt"
hm_ok "Both dependencies are declared in Chart.yaml and locked"

hm_info "Checking the release..."
hm_require_deployed payroll
[ "$(hm_release_revision payroll)" -ge 2 ] || hm_fail "Release payroll is still on its first revision — nothing was rolled out"
for d in tax-tables pay-calendar; do
  hm_manifest_json payroll | jq -e --arg n "payroll-$d" 'any(.[]; .kind=="Deployment" and .metadata.name==$n)' >/dev/null \
    || hm_fail "The payroll release does not contain Deployment payroll-$d"
  hm_wait_rollout "deployment/payroll-$d" "$NS" 90s
done
hm_wait_rollout deployment/payroll-api "$NS" 90s
ty="$(hm_jsonpath deployment/payroll-tax-tables '{.metadata.name}')"
[ "$ty" = "payroll-tax-tables" ] || hm_fail "tax-tables disappeared"
hm_pass "payroll runs with both of its dependencies."
