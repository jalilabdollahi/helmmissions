#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=shopfront
hm_require_deployed "$REL"

hm_info "Checking the frontend..."
hm_wait_rollout deployment/shopfront-backend "$NS" 60s
okpods=0
for _ in $(seq 1 30); do
  okpods="$(hm_pods_json app.kubernetes.io/name=shopfront-frontend,app.kubernetes.io/instance=$REL | jq '[.[]|select(.status.containerStatuses[0].ready==true)]|length')"
  [ "$okpods" -ge 1 ] && break
  sleep 2
done
if [ "$okpods" -lt 1 ]; then
  kubectl logs deploy/shopfront-frontend -n "$NS" --tail=3 >"$HM_TMP/w.txt" 2>&1
  hm_fail "The frontend pod is not Ready — it still cannot reach the catalog" "$HM_TMP/w.txt"
fi
hm_ok "The frontend reaches the catalog backend"

hm_info "Checking that the backend is still protected..."
if hm_http_check "http://shopfront-backend.$NS.svc/" "$NS" 1 >/dev/null; then
  hm_fail "An unrelated pod can reach the catalog backend — the zero-trust isolation is gone"
fi
hm_ok "A pod outside the web tier is still blocked"

hm_info "Checking that the fix lives in the release..."
manifest="$(hm_manifest_json "$REL")"
echo "$manifest" | jq -e '[.[]|select(.kind=="NetworkPolicy")]|length>0' >/dev/null \
  || hm_fail "The release no longer ships any NetworkPolicy — isolation was removed"
echo "$manifest" | jq '.' > "$HM_TMP/manifest.json"
"$HM_PYTHON" - "$HM_TMP/manifest.json" <<'PY' || exit 1
import json, sys
docs = json.load(open(sys.argv[1]))
fe = next((d for d in docs if d["kind"] == "Deployment" and d["metadata"]["name"].endswith("-frontend")), None)
if not fe:
    print("❌ The release has no frontend Deployment"); sys.exit(1)
labels = fe["spec"]["template"]["metadata"].get("labels", {})
ok = False
for d in docs:
    if d["kind"] != "NetworkPolicy":
        continue
    for rule in d["spec"].get("ingress") or []:
        for peer in rule.get("from") or []:
            sel = peer.get("podSelector")
            if sel is None or "namespaceSelector" in peer or "ipBlock" in peer:
                continue
            ml = sel.get("matchLabels") or {}
            if sel.get("matchExpressions"):
                continue
            if ml and all(labels.get(k) == v for k, v in ml.items()):
                ok = True
if not ok:
    print("❌ The policies stored in the release do not admit the frontend — a live edit would be reverted by the next upgrade")
    sys.exit(1)
print("✅ The release's policies name the frontend's labels")
PY

hm_pass "The web tier talks to the catalog and nobody else does."
