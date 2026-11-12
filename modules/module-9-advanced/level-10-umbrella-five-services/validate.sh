#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/marketplace"
SERVICES=(gateway catalog cart pricing notifier)

hm_info "Checking the umbrella structure..."
for s in "${SERVICES[@]}"; do
  [ -f "$CHART/charts/$s/Chart.yaml" ] || hm_fail "Subchart $s is missing from marketplace/charts/ — the five services must stay separate subcharts"
done

images_of() { jq -r '.[] | select(.kind=="Deployment") | "\(.metadata.name) \([.spec.template.spec.containers[].image] | join(","))"'; }

hm_info "Rendering the umbrella..."
out="$(hm_render_json "$CHART")" || true
[ -n "$out" ] && [ "$out" != "[]" ] || hm_fail "helm template marketplace fails" "$HM_TMP/render-err.txt"
n="$(echo "$out" | jq '[.[] | select(.kind=="Deployment")] | length')"
[ "$n" = 5 ] || hm_fail "The umbrella renders $n Deployments, expected 5"
for s in "${SERVICES[@]}"; do
  echo "$out" | jq -e --arg n "hm-render-$s" 'any(.[]; .kind=="Deployment" and .metadata.name==$n)' >/dev/null || hm_fail "No Deployment for the $s service is rendered"
done
bad="$(echo "$out" | images_of | grep -v ' docker.io/' | head -1 || true)"
[ -z "$bad" ] || hm_fail "A service does not use global.imageRegistry (docker.io): ${bad}"
hm_ok "All 5 services render with images from global.imageRegistry"

hm_info "Switching the global registry..."
out2="$(hm_render_json "$CHART" --set global.imageRegistry=mirror.example.test)" || true
[ -n "$out2" ] && [ "$out2" != "[]" ] || hm_fail "helm template with another global.imageRegistry fails" "$HM_TMP/render-err.txt"
bad="$(echo "$out2" | images_of | grep -v ' mirror.example.test/' | head -1 || true)"
[ -z "$bad" ] || hm_fail "Changing global.imageRegistry does not move every image: $(echo "$bad" | cut -d' ' -f1) still uses ${bad#* }"
hm_ok "One global value moves all five services"

hm_info "Checking the release..."
hm_require_deployed marketplace
[ "$(hm_release_chart marketplace)" = "marketplace-5.0.0" ] || hm_fail "Release marketplace runs chart '$(hm_release_chart marketplace)'"
for s in "${SERVICES[@]}"; do
  hm_wait_rollout "deployment/marketplace-$s" "$NS" 90s
  img="$(hm_jsonpath "deployment/marketplace-$s" '{.spec.template.spec.containers[0].image}')"
  case "$img" in docker.io/*) ;; *) hm_fail "Live deployment marketplace-$s uses image '$img', expected one from docker.io" ;; esac
done
hm_pass "The marketplace umbrella is up and every service honours the global registry."
