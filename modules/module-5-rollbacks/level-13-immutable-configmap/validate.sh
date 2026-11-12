#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/feature-flags"

hm_info "Checking the chart..."
a="$(hm_render_json "$CHART" --set flags.darkMode=false)" || hm_fail "The chart does not render" "$HM_TMP/render-err.txt"
b="$(hm_render_json "$CHART" --set flags.darkMode=true)" || hm_fail "The chart does not render" "$HM_TMP/render-err.txt"
an="$(echo "$a" | jq -r '[.[]|select(.kind=="ConfigMap")][0].metadata.name')"
bn="$(echo "$b" | jq -r '[.[]|select(.kind=="ConfigMap")][0].metadata.name')"
[ "$an" != "$bn" ] || hm_fail "Changing flag data renders the same ConfigMap name ('$an') - an immutable ConfigMap can never be updated in place"
[ "$(echo "$a" | jq -r '[.[]|select(.kind=="ConfigMap")][0].immutable')" = "true" ] || hm_fail "The ConfigMap is no longer immutable"
[ "$(echo "$a" | jq -r '[.[]|select(.kind=="Deployment")][0].spec.template.spec.volumes[0].configMap.name')" = "$an" ] \
  || hm_fail "The Deployment does not mount the rendered ConfigMap"
hm_ok "Chart: immutable ConfigMap whose name follows its content ($an -> $bn)"

hm_info "Checking the release..."
hm_require_deployed flags
[ "$(hm_release_chart flags)" = "feature-flags-1.1.0" ] || hm_fail "Release flags runs chart '$(hm_release_chart flags)', expected feature-flags-1.1.0"
hm_wait_rollout deployment/flags "$NS" 90s
live="$(kubectl get configmap -n "$NS" -o json | jq -r '[.items[]|select(.metadata.annotations["meta.helm.sh/release-name"]=="flags")][0].immutable')"
[ "$live" = "true" ] || hm_fail "The live ConfigMap is not immutable"
for _ in 1 2 3 4; do
  hm_http_check http://flags/flags.json >"$HM_TMP/body.txt" || hm_fail "http://flags/flags.json does not answer"
  grep -q '"checkoutV2":true' "$HM_TMP/body.txt" && break
  sleep 3
done
grep -q '"checkoutV2":true' "$HM_TMP/body.txt" || hm_fail "The service does not serve checkoutV2=true" "$HM_TMP/body.txt"

hm_info "Proving the chart survives a flag change (throwaway release in helmissions-verify)..."
trap 'kubectl delete namespace helmissions-verify --wait=false >/dev/null 2>&1; rm -rf "$HM_TMP"' EXIT
kubectl create namespace helmissions-verify >/dev/null 2>&1 || true
helm install flags-verify "$CHART" -n helmissions-verify --wait --timeout 90s >"$HM_TMP/vi.txt" 2>&1 || hm_fail "A fresh install of the chart fails" "$HM_TMP/vi.txt"
helm upgrade flags-verify "$CHART" -n helmissions-verify --set flags.darkMode=true --wait --timeout 90s >"$HM_TMP/vu.txt" 2>&1 \
  || hm_fail "Changing a flag still makes the upgrade fail" "$HM_TMP/vu.txt"

hm_pass "Flags change safely and stay immutable."
