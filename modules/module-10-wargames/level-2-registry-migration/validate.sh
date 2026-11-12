#!/bin/bash
set -uo pipefail
source "$HM_LIB"

NEW="localhost:5001/"
imgs() { jq -r '.[]|select(.kind=="Deployment")|.spec.template.spec.containers[].image'; }

hm_info "Checking the releases..."
for r in shop-cart shop-search shop-media; do hm_require_deployed "$r"; done

hm_info "Checking the pods and their images..."
for d in shop-cart shop-search shop-search-indexer shop-media; do hm_wait_rollout "deployment/$d" "$NS" 60s; done
bad="$(kubectl get pods -n "$NS" -o json | jq -r --arg n "$NEW" '[.items[]|select(.metadata.deletionTimestamp==null)|.spec.containers[].image|select(startswith($n)|not)]|join(", ")')"
[ -z "$bad" ] || hm_fail "Some running containers still use images outside the new registry: $bad"
hm_ok "All running containers use images from $NEW"

hm_info "Checking what the workspace would deploy..."
for rel in shop-cart shop-search shop-media; do
  out="$(hm_render_json "$SANDBOX/$rel" -f "$SANDBOX/values/global.yaml" -f "$SANDBOX/values/$rel.yaml")" || hm_fail "$rel does not render from the workspace" "$HM_TMP/render-err.txt"
  list="$(echo "$out" | imgs)"
  [ -n "$list" ] || hm_fail "$rel renders no workloads"
  echo "$list" | grep -v "^$NEW" >"$HM_TMP/badimg.txt" && hm_fail "$rel: the workspace would deploy images from another registry: $(tr '\n' ' ' <"$HM_TMP/badimg.txt")"
done
hm_ok "Workspace renders only new-registry images"

hm_info "Checking the services..."
for s in shop-cart shop-search shop-media; do
  hm_http_check "http://$s/" >"$HM_TMP/$s.txt" || hm_fail "Service $s does not answer"
  grep -q "Name: $s" "$HM_TMP/$s.txt" || hm_fail "Service $s answered, but not from the expected workload" "$HM_TMP/$s.txt"
done
hm_pass "Every shop service runs from the new registry."
