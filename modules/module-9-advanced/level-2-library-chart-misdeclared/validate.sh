#!/bin/bash
set -uo pipefail
source "$HM_LIB"

LIB="$SANDBOX/mqlib"
CONSUMERS=(invoice-mailer receipt-mailer)

hm_info "Checking how mqlib is declared..."
[ -f "$LIB/Chart.yaml" ] || hm_fail "mqlib/Chart.yaml is missing from the workspace"
[ "$(hm_yaml_get "$LIB/Chart.yaml" type | jq -r '.')" = "library" ] \
  || hm_fail "mqlib is declared as an application chart — Helm would happily install it on its own and render everything in templates/"
helm install mqlib-probe "$LIB" -n "$NS" --dry-run=client >"$HM_TMP/probe.txt" 2>&1 \
  && hm_fail "mqlib can be installed as a release — it is not a library chart"
grep -qi "library charts are not installable" "$HM_TMP/probe.txt" || hm_fail "Unexpected result when trying to install mqlib on its own" "$HM_TMP/probe.txt"
hm_ok "mqlib is a library chart"

hm_info "Rendering the consumers..."
for c in "${CONSUMERS[@]}"; do
  out="$(hm_render_json "$SANDBOX/$c")" || true
  [ -n "$out" ] && [ "$out" != "[]" ] || hm_fail "helm template $c fails (is the vendored copy of mqlib in charts/ current?)" "$HM_TMP/render-err.txt"
  echo "$out" | jq -e 'any(.[]; .metadata.name=="mq-defaults")' >/dev/null \
    && hm_fail "$c still renders a ConfigMap called mq-defaults — it comes from the vendored mqlib"
  echo "$out" | jq -e 'any(.[]; .kind=="ConfigMap" and .metadata.name=="hm-render-mq" and (.data.broker // "") != "")' >/dev/null \
    || hm_fail "$c does not render its <release>-mq ConfigMap from the mqlib helpers"
  n="$(echo "$out" | jq 'length')"
  [ "$n" = 2 ] || hm_fail "$c renders $n objects, expected exactly its ConfigMap and its Deployment"
done
hm_ok "Consumers render only their own objects"

hm_info "Checking the releases..."
for c in "${CONSUMERS[@]}"; do
  hm_require_deployed "$c"
  hm_manifest_json "$c" | jq -e 'any(.[]; .metadata.name=="mq-defaults")' >/dev/null && hm_fail "Release $c still contains the stray mq-defaults ConfigMap"
  hm_wait_rollout "deployment/$c" "$NS" 90s
  want="$(hm_yaml_get "$SANDBOX/$c/values.yaml" mq.broker | jq -r '.')"
  got="$(hm_jsonpath "configmap/$c-mq" '{.data.broker}')"
  [ "$got" = "$want" ] || hm_fail "ConfigMap $c-mq has broker '$got', expected '$want'"
done
[ "$(hm_release_revision invoice-mailer)" -ge 2 ] || hm_fail "invoice-mailer is still at revision 1 — the stray object is still part of it"
kubectl get configmap mq-defaults -n "$NS" >/dev/null 2>&1 && hm_fail "ConfigMap mq-defaults still exists in namespace $NS"
hm_pass "mqlib is a real library and both mailers are live."
