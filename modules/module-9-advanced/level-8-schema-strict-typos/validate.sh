#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/queue-worker"
SCHEMA="$CHART/values.schema.json"

hm_info "Checking the schema file..."
[ -f "$SCHEMA" ] || hm_fail "queue-worker has no values.schema.json"
jq -e type "$SCHEMA" >/dev/null 2>&1 || hm_fail "values.schema.json is not valid JSON"

must_fail() { # description, args...
  local d="$1"; shift
  if helm template qw "$CHART" -n "$NS" "$@" >"$HM_TMP/neg.txt" 2>&1; then
    hm_fail "The chart accepted $d — the schema should reject it"
  fi
}
must_pass() {
  local d="$1"; shift
  helm template qw "$CHART" -n "$NS" "$@" >"$HM_TMP/pos.txt" 2>&1 || hm_fail "The schema rejects $d, which is a documented value" "$HM_TMP/pos.txt"
}
helm template qw "$CHART" -n "$NS" >"$HM_TMP/default.txt" 2>&1 || hm_fail "The chart does not render with its default values" "$HM_TMP/default.txt"
helm lint "$CHART" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint fails" "$HM_TMP/lint.txt"

hm_info "Typos must be rejected..."
must_fail "a misspelled top-level key (replicaCnt)" --set replicaCnt=3
must_fail "an unknown key under image (tagg)" --set image.tagg=v1.10
must_fail "an unknown key under probes.readiness (periodSecond)" --set probes.readiness.periodSecond=5
must_fail "an unknown key under resources (limts)" --set resources.limts.memory=96Mi
must_fail "an unknown key under resources.limits (memry)" --set resources.limits.memry=96Mi
must_fail "an unknown key under resources.requests (cpuu)" --set resources.requests.cpuu=10m
must_fail "a string replicaCount" --set-string replicaCount=three
must_fail "a string concurrency" --set-string concurrency=many
hm_ok "Unknown keys and wrong types are rejected"

hm_info "Documented values must still work..."
must_pass "replicaCount" --set replicaCount=5
must_pass "image.repository/tag/pullPolicy" --set image.repository=traefik/whoami --set image.tag=v1.10 --set image.pullPolicy=Always
must_pass "concurrency" --set concurrency=32
must_pass "probes.readiness" --set probes.readiness.periodSeconds=10 --set probes.readiness.initialDelaySeconds=3
must_pass "resources limits and requests" --set resources.limits.cpu=100m --set resources.limits.memory=128Mi --set resources.requests.cpu=20m --set resources.requests.memory=32Mi
must_pass "free-form extraEnv" --set extraEnv.LOG_LEVEL=debug --set extraEnv.REGION=eu-west
must_pass "free-form podAnnotations" --set-string podAnnotations.team=orders
hm_ok "The schema accepts every documented value"

hm_info "Checking values-prod.yaml..."
out="$(hm_render_json "$CHART" -f "$SANDBOX/values-prod.yaml")" || true
[ -n "$out" ] && [ "$out" != "[]" ] || hm_fail "The chart rejects values-prod.yaml" "$HM_TMP/render-err.txt"
echo "$out" | jq -e '.[] | select(.kind=="Deployment") | select(.spec.replicas==3 and .spec.template.spec.containers[0].readinessProbe.periodSeconds==5)' >/dev/null \
  || hm_fail "values-prod.yaml does not produce 3 replicas with a 5 second readiness period"
hm_ok "values-prod.yaml is valid and expresses the intended production settings"

hm_info "Checking the release..."
hm_require_deployed queue-worker
[ "$(hm_release_revision queue-worker)" -ge 2 ] || hm_fail "Release queue-worker is still at revision 1"
hm_wait_rollout deployment/queue-worker "$NS" 90s
[ "$(hm_jsonpath deployment/queue-worker '{.status.readyReplicas}')" = 3 ] || hm_fail "Deployment queue-worker does not have 3 ready replicas"
[ "$(hm_jsonpath deployment/queue-worker '{.spec.template.spec.containers[0].readinessProbe.periodSeconds}')" = 5 ] || hm_fail "The running pods are not probed every 5 seconds"
[ "$(hm_jsonpath deployment/queue-worker '{.spec.template.spec.containers[0].env[0].value}')" = 16 ] || hm_fail "The running pods do not use concurrency 16"
hm_pass "queue-worker now refuses unknown values, and prod runs as intended."
