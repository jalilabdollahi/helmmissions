#!/bin/bash
set -uo pipefail
source "$HM_LIB"

K="$SANDBOX/platform/kustomization.yaml"
hm_info "Checking the kustomization..."
[ -f "$K" ] || hm_fail "platform/kustomization.yaml is missing"
hm_yaml_get "$K" helmCharts | jq -e 'any(.[]?; .name=="catalog-api")' >/dev/null \
  || hm_fail "platform/kustomization.yaml no longer inflates catalog-api through helmCharts"
kubectl kustomize --enable-helm "$SANDBOX/platform" >"$HM_TMP/built.yaml" 2>"$HM_TMP/built-err.txt" \
  || hm_fail "kubectl kustomize --enable-helm platform fails" "$HM_TMP/built-err.txt"
built="$("$HM_PYTHON" -c 'import json,sys,yaml; print(json.dumps([d for d in yaml.safe_load_all(open(sys.argv[1])) if d]))' "$HM_TMP/built.yaml")"
dep="$(echo "$built" | jq -c '[.[] | select(.kind=="Deployment" and .metadata.name=="catalog-api")][0] // empty')"
[ -n "$dep" ] || hm_fail "The kustomize output has no Deployment catalog-api"
[ "$(echo "$dep" | jq '.spec.replicas')" = 2 ] || hm_fail "The rendered Deployment has $(echo "$dep" | jq '.spec.replicas') replicas — the prod values file was not applied"
[ "$(echo "$dep" | jq -r '.spec.template.spec.containers[0].env[0].value')" = 600 ] || hm_fail "CACHE_TTL_SECONDS is not 600 in the rendered output — the prod values file was not applied"
[ "$(echo "$dep" | jq -r '.spec.template.metadata.labels.env // ""')" = prod ] || hm_fail "The rendered pod template has no env=prod label"
echo "$built" | jq -e 'all(.[]; (.metadata.labels.env // "") == "prod")' >/dev/null || hm_fail "Not every rendered object carries env=prod"
hm_ok "kustomize renders the prod catalog-api"

hm_info "Checking the cluster..."
hm_wait_rollout deployment/catalog-api "$NS" 90s
live="$(kubectl get deployment catalog-api -n "$NS" -o json)"
[ "$(echo "$live" | jq '.spec.replicas')" = 2 ] || hm_fail "Live Deployment catalog-api does not have 2 replicas"
[ "$(echo "$live" | jq -r '.spec.template.spec.containers[0].env[0].value')" = 600 ] || hm_fail "Live catalog-api pods do not run with CACHE_TTL_SECONDS=600"
[ "$(echo "$live" | jq -r '.metadata.labels.env // ""')" = prod ] || hm_fail "Live Deployment catalog-api has no env=prod label (the kustomize output was not what got applied)"
[ "$(echo "$live" | jq -r '.spec.template.metadata.labels.env // ""')" = prod ] || hm_fail "Live catalog-api pods have no env=prod label"
[ "$(echo "$live" | jq -r '.metadata.annotations["meta.helm.sh/release-name"] // ""')" = "" ] || hm_fail "catalog-api is owned by a Helm release — the folder is meant to be rendered by kustomize and applied with kubectl"
ready="$(hm_jsonpath deployment/catalog-api '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment catalog-api has ${ready:-0}/2 ready pods"
[ "$(hm_endpoints_count catalog-api)" -ge 2 ] || hm_fail "Service catalog-api has fewer than 2 ready endpoints"
hm_pass "The catalog is rendered by kustomize from the Helm chart and running."
