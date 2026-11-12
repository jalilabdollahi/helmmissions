#!/bin/bash
set -uo pipefail
source "$HM_LIB"

LEAKED='Tr0ub4dor&3-ledger-prod'
REL=ledger-api

hm_info "Scanning the workspace for plaintext passwords..."
if grep -rIlF -- "$LEAKED" "$SANDBOX" >"$HM_TMP/leak.txt" 2>/dev/null && [ -s "$HM_TMP/leak.txt" ]; then
  hm_fail "The leaked password is still written in the workspace" "$HM_TMP/leak.txt"
fi
"$HM_PYTHON" - "$SANDBOX" >"$HM_TMP/scan.txt" <<'PY'
import os, re, sys, yaml
bad = []
def walk(node, path, f):
    if isinstance(node, dict):
        for k, v in node.items():
            if re.search(r"pass(word|wd)?$", str(k), re.I) and isinstance(v, str) and v.strip() and "{{" not in v:
                bad.append(f"{f}: {path}.{k} holds a literal value")
            walk(v, f"{path}.{k}", f)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, f"{path}[{i}]", f)
for root, _, files in os.walk(sys.argv[1]):
    if "/templates" in root:
        continue
    for name in files:
        if name.endswith((".yaml", ".yml")):
            p = os.path.join(root, name)
            try:
                for d in yaml.safe_load_all(open(p)):
                    walk(d, "", os.path.relpath(p, sys.argv[1]))
            except Exception:
                pass
if bad: print("\n".join(bad))
PY
[ ! -s "$HM_TMP/scan.txt" ] || hm_fail "A values file in the workspace still carries a plaintext password" "$HM_TMP/scan.txt"
hm_ok "No plaintext password in the workspace"

hm_info "Checking the release..."
hm_require_deployed "$REL"
uv="$(hm_user_values "$REL")"
if echo "$uv" | jq -e '[.. | scalars | strings | select(test("Tr0ub4dor"))] | length > 0' >/dev/null; then
  hm_fail "helm get values still exposes the leaked password"
fi
echo "$uv" | jq -e '[paths(scalars) as $p | select(($p|map(tostring)|join(".")|test("pass";"i")) and (getpath($p)|type=="string") and (getpath($p)|length>0))] | length == 0' >/dev/null 2>&1 \
  || hm_fail "The release's user-supplied values still contain a password (visible with 'helm get values')"
manifest="$(hm_manifest_json "$REL")"
env="$(echo "$manifest" | jq -c '[.[]|select(.kind=="Deployment")|.spec.template.spec.containers[].env[]?|select(.name=="DB_PASSWORD")][0]')"
[ "$env" != "null" ] || hm_fail "The Deployment has no DB_PASSWORD variable"
echo "$env" | jq -e '.value' >/dev/null 2>&1 && hm_fail "DB_PASSWORD is still a literal value in the Deployment"
sname="$(echo "$env" | jq -r '.valueFrom.secretKeyRef.name // empty')"
skey="$(echo "$env" | jq -r '.valueFrom.secretKeyRef.key // empty')"
[ -n "$sname" ] && [ -n "$skey" ] || hm_fail "DB_PASSWORD does not come from a secretKeyRef"
echo "$manifest" | jq -e --arg n "$sname" '[.[]|select(.kind=="Secret" and .metadata.name==$n)]|length==0' >/dev/null \
  || hm_fail "Secret '$sname' is rendered by the chart — the password would still travel through Helm values/manifests"
hm_ok "DB_PASSWORD references Secret '$sname' (key '$skey')"

hm_info "Checking the Secret..."
sec="$(kubectl get secret "$sname" -n "$NS" -o json 2>/dev/null || true)"
[ -n "$sec" ] || hm_fail "Secret '$sname' does not exist in namespace $NS"
[ "$(echo "$sec" | jq -r '.metadata.annotations["meta.helm.sh/release-name"] // empty')" = "" ] || hm_fail "Secret '$sname' is owned by a Helm release"
pw="$(echo "$sec" | jq -r --arg k "$skey" '.data[$k] // empty' | base64 -d 2>/dev/null || true)"
[ -n "$pw" ] || hm_fail "Secret '$sname' has no value under key '$skey'"
[ "$pw" != "$LEAKED" ] || hm_fail "The Secret still holds the leaked password — it has to be rotated"
hm_ok "Secret holds a rotated password"

hm_info "Checking the workload..."
hm_wait_rollout "deployment/$REL" "$NS" 90s
live="$(hm_pods_json app.kubernetes.io/instance=$REL | jq -c '[.[]|select(.status.phase=="Running")|.spec.containers[0].env[]|select(.name=="DB_PASSWORD")]|.[0]')"
echo "$live" | jq -e '.valueFrom.secretKeyRef' >/dev/null 2>&1 || hm_fail "The running pod still gets DB_PASSWORD as a literal value"
ready="$(hm_jsonpath "deployment/$REL" '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 1 ] || hm_fail "Deployment $REL has no ready pod"

hm_pass "ledger-api reads its password from a Secret — nothing sensitive is left in git or in the release."
