#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/edge-gateway"
LABEL="edge-platform"

# all_ok JSON → prints problems (empty when every object has the label, the pod template too, and the sidecar exists)
problems() {
  jq -r --arg l "$LABEL" '
    [ .[] | select((.metadata.labels["cost-center"] // "") != $l) | "\(.kind)/\(.metadata.name) has no cost-center label" ]
    + [ .[] | select(.kind=="Deployment") | select((.spec.template.metadata.labels["cost-center"] // "") != $l) | "pod template of \(.metadata.name) has no cost-center label" ]
    + [ .[] | select(.kind=="Deployment") | select(([.spec.template.spec.containers[].name] | index("log-shipper")) == null) | "Deployment \(.metadata.name) has no log-shipper container" ]
    + [ .[] | select(.kind=="Deployment") | select((.spec.selector.matchLabels | has("cost-center"))) | "selector of \(.metadata.name) was changed" ]
    | .[]' 2>/dev/null
}

hm_info "Checking the vendored chart is untouched..."
diff -r "$LEVEL_DIR/broken/edge-gateway" "$CHART" >"$HM_TMP/chart-diff.txt" 2>&1 \
  || hm_fail "The vendored chart edge-gateway/ was modified — policy says it must stay as upstream shipped it" "$HM_TMP/chart-diff.txt"
hm_ok "edge-gateway/ is unchanged"

hm_info "Checking that an installed post-renderer plugin works..."
works=""
while read -r name _ type _; do
  [ "$type" = "postrenderer/v1" ] || continue
  out="$(helm template edge-gateway "$CHART" -n "$NS" --post-renderer "$name" 2>"$HM_TMP/pr-err.txt" | "$HM_PYTHON" -c '
import json, sys, yaml
print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))' 2>/dev/null)" || continue
  [ -n "$out" ] || continue
  if [ -z "$(echo "$out" | problems)" ] && [ "$(echo "$out" | jq 'length')" -ge 4 ]; then works="$name"; break; fi
done < <(helm plugin list 2>/dev/null | tail -n +2)
[ -n "$works" ] || hm_fail "No installed post-renderer plugin renders edge-gateway with the label and the sidecar (try: helm template edge-gateway ./edge-gateway --post-renderer hm-cost-labeler)" "$HM_TMP/pr-err.txt"
hm_ok "Post-renderer plugin '$works' produces the required output"

hm_info "Checking the release..."
hm_require_deployed edge-gateway
[ "$(hm_release_revision edge-gateway)" -ge 2 ] || hm_fail "Release edge-gateway is still at revision 1"
[ "$(hm_release_chart edge-gateway)" = "edge-gateway-2.4.1" ] || hm_fail "Release edge-gateway no longer runs the vendored chart 2.4.1"
manifest="$(hm_manifest_json edge-gateway)"
p="$(echo "$manifest" | problems | head -3)"
[ -z "$p" ] || hm_fail "The stored release manifest is missing the policy (kubectl changes do not count — they are not in the release): $(echo "$p" | head -1)"
hm_wait_rollout deployment/edge-gateway "$NS" 90s
ready="$(hm_jsonpath deployment/edge-gateway '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment edge-gateway has ${ready:-0}/2 ready pods"
bad="$(hm_pods_json app.kubernetes.io/instance=edge-gateway | jq -r '[.[] | select((.spec.containers|length) != 2 or ([.status.containerStatuses[]?.ready] | all | not) or (.metadata.labels["cost-center"] != "edge-platform"))] | length')"
[ "$bad" = 0 ] || hm_fail "$bad pod(s) of edge-gateway are not running both containers with the cost-center label"
hm_pass "edge-gateway carries the cost-center label and log-shipper sidecar via post-render."
