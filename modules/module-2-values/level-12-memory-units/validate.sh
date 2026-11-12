#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_require_deployed image-resizer

to_bytes() {
  "$HM_PYTHON" -c '
import re, sys
m = re.fullmatch(r"([0-9.]+)([A-Za-z]*)", sys.argv[1].strip())
mult = {"": 1, "k": 10**3, "M": 10**6, "G": 10**9, "Ki": 2**10, "Mi": 2**20, "Gi": 2**30}
print(int(float(m.group(1)) * mult[m.group(2)]) if m and m.group(2) in mult else -1)' "$1"
}

hm_info "Checking the memory limit..."
lim="$(hm_all_values image-resizer | jq -r '.resources.limits.memory // empty')"
[ -n "$lim" ] || hm_fail "resources.limits.memory is not set in the release values"
[ "$(to_bytes "$lim")" = "268435456" ] || hm_fail "The release configures a memory limit of '$lim' - expected 256Mi"
dl="$(kubectl get deploy image-resizer -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')"
[ "$(to_bytes "$dl")" = "268435456" ] || hm_fail "The live Deployment has a memory limit of '$dl' - expected 256Mi, set through the release"
hm_ok "Memory limit is 256Mi"

hm_info "Checking the pods..."
kubectl rollout status deployment/image-resizer -n "$NS" --timeout=90s >"$HM_TMP/r.txt" 2>&1 || hm_fail "image-resizer did not roll out" "$HM_TMP/r.txt"
ready="$(hm_jsonpath deployment/image-resizer '{.status.readyReplicas}')"
[ "${ready:-0}" = "2" ] || hm_fail "Only ${ready:-0}/2 pods are ready"
hm_pass "image-resizer workers are running with a 256Mi limit."
