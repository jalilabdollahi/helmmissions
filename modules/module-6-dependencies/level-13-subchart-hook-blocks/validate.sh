#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/checkout"

hm_info "Checking the chart still runs the migrator as a subchart hook..."
hm_yaml_get "$CHART/Chart.yaml" dependencies | jq -e 'any(.[]; .name=="schema-migrator")' >/dev/null \
  || hm_fail "checkout/Chart.yaml no longer depends on schema-migrator"

hm_info "Checking the release..."
hm_require_deployed checkout
chart="$(hm_release_chart checkout)"
[ "$chart" = "checkout-6.2.0" ] || hm_fail "Release checkout runs chart '$chart', expected checkout-6.2.0"
hm_wait_rollout deployment/checkout-api "$NS" 90s

hm_info "Checking the migration hook really ran and succeeded..."
job="$(kubectl get job checkout-schema-migrator-migrate -n "$NS" -o json 2>/dev/null)" \
  || hm_fail "The migration Job checkout-schema-migrator-migrate does not exist: the hook did not run for this release"
[ "$(echo "$job" | jq -r '.status.succeeded // 0')" -ge 1 ] \
  || hm_fail "The migration Job has not completed successfully (succeeded=$(echo "$job" | jq -r '.status.succeeded // 0'), failed=$(echo "$job" | jq -r '.status.failed // 0'))"
jhost="$(echo "$job" | jq -r '.spec.template.spec.containers[0].env[] | select(.name=="DB_HOST") | .value')"
apihost="$(hm_jsonpath deployment/checkout-api '{.spec.template.spec.containers[0].env[?(@.name=="DB_HOST")].value}')"
[ -n "$jhost" ] && [ "$jhost" = "$apihost" ] || hm_fail "The migration ran against database host '${jhost}', but the API uses '${apihost}'"
pod="$(kubectl get pods -n "$NS" -l job-name=checkout-schema-migrator-migrate -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
kubectl logs "$pod" -n "$NS" 2>/dev/null | grep -q "migrations applied" || hm_fail "The migration Job's log does not show 'migrations applied'"
hm_pass "The migration hook ran against $jhost and checkout is deployed."
