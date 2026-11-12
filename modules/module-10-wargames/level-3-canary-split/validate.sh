#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the releases..."
hm_require_deployed catalog-stable
hm_require_deployed catalog-canary

hm_info "Checking the pods behind the Service..."
hm_wait_rollout deployment/catalog-stable "$NS" 90s
hm_wait_rollout deployment/catalog-canary "$NS" 90s
for _ in $(seq 1 20); do
  total="$(kubectl get pods -n "$NS" -l track --no-headers | wc -l | tr -d ' ')"
  [ "$total" = "10" ] && break
  sleep 2
done
stable_n="$(hm_pods_json "app.kubernetes.io/instance=catalog-stable" | jq '[.[]|select(.status.containerStatuses[0].ready==true)]|length')"
canary_n="$(hm_pods_json "app.kubernetes.io/instance=catalog-canary" | jq '[.[]|select(.status.containerStatuses[0].ready==true)]|length')"
[ "$stable_n" = "9" ] || hm_fail "catalog-stable has $stable_n ready pods, the plan says 9"
[ "$canary_n" = "1" ] || hm_fail "catalog-canary has $canary_n ready pods, the plan says 1"
eps="$(kubectl get endpointslices -n "$NS" -l kubernetes.io/service-name=catalog -o json | jq '[.items[].endpoints[]?|select(.conditions.ready!=false)]')"
[ "$(echo "$eps" | jq length)" = "10" ] || hm_fail "Service catalog has $(echo "$eps" | jq length) ready endpoints, expected 10"
[ "$(echo "$eps" | jq '[.[]|select(.targetRef.name|startswith("catalog-canary"))]|length')" = "1" ] || hm_fail "The canary pod is not one of the Service's endpoints"
hm_ok "10 endpoints: 9 stable + 1 canary"

hm_info "Checking what the workspace renders..."
for t in stable canary; do
  want=9; [ "$t" = canary ] && want=1
  r="$(hm_render_json "$SANDBOX/catalog" -f "$SANDBOX/values-$t.yaml")" || hm_fail "catalog does not render with values-$t.yaml" "$HM_TMP/render-err.txt"
  [ "$(echo "$r" | jq '[.[]|select(.kind=="Deployment")][0].spec.replicas')" = "$want" ] || hm_fail "values-$t.yaml would deploy a different replica count than $want"
  [ "$(echo "$r" | jq -r '[.[]|select(.kind=="Deployment")][0].spec.template.metadata.labels["app.kubernetes.io/name"]')" = "catalog" ] || hm_fail "values-$t.yaml renders pods the Service would not select"
done
hm_ok "Workspace matches the plan"

hm_info "Sampling real traffic..."
name="hm-sample-$RANDOM"
kubectl run "$name" -n "$NS" --image=curlimages/curl:8.10.1 --image-pull-policy=IfNotPresent --restart=Never \
  --labels=helmissions.io/probe=true --command -- sh -c 'for i in $(seq 1 100); do curl -s --max-time 3 http://catalog/; done' >/dev/null 2>&1
for _ in $(seq 1 60); do
  ph="$(kubectl get pod "$name" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)"
  [ "$ph" = "Succeeded" ] || [ "$ph" = "Failed" ] && break
  sleep 1
done
kubectl logs "$name" -n "$NS" >"$HM_TMP/sample.txt" 2>/dev/null
kubectl delete pod "$name" -n "$NS" --now --wait=false >/dev/null 2>&1
c="$(grep -c "catalog canary" "$HM_TMP/sample.txt" || true)"
s="$(grep -c "catalog stable" "$HM_TMP/sample.txt" || true)"
[ "$((c + s))" -ge 90 ] || hm_fail "Too few answers from the Service ($((c + s)) of 100)"
[ "$c" -ge 1 ] || hm_fail "No request out of 100 reached the canary"
[ "$c" -le 30 ] || hm_fail "The canary answered $c of 100 requests - far above the planned 10%"
hm_pass "Canary at ~10%: $c of 100 sampled requests hit it."
