#!/bin/bash
set -uo pipefail
source "$HM_LIB"

REL=payments-gateway
TRUSTED="$LEVEL_DIR/assets/trusted-pubring.gpg"
cd "$SANDBOX"

hm_info "Looking for the signed package..."
pkg="$(ls dist/payments-gateway-*.tgz 2>/dev/null | head -n1 || true)"
[ -n "$pkg" ] || hm_fail "No packaged chart (dist/payments-gateway-*.tgz) in the workspace"
[ -f "$pkg.prov" ] || hm_fail "$pkg has no provenance file ($pkg.prov) — the package is unsigned"
helm verify "$pkg" --keyring "$TRUSTED" >"$HM_TMP/verify.txt" 2>&1 \
  || hm_fail "helm verify rejects the package with the trusted release key" "$HM_TMP/verify.txt"
grep -q "Signed by: HelmMissions Release Signer" "$HM_TMP/verify.txt" || hm_fail "The package was not signed by the release key" "$HM_TMP/verify.txt"
hm_ok "$pkg verifies against the trusted release key"

hm_info "Checking the release..."
hm_require_deployed "$REL"
chart="$(hm_release_chart "$REL")"
pkgver="$(helm show chart "$pkg" | sed -n 's/^version: //p')"
[ "$chart" = "payments-gateway-$pkgver" ] || hm_fail "Release runs '$chart', not the signed package (payments-gateway-$pkgver)"

# The live manifest must be exactly what the signed package renders.
helm template "$REL" "$pkg" -n "$NS" 2>/dev/null | "$HM_PYTHON" -c '
import json,sys,yaml
print(json.dumps(sorted([d for d in yaml.safe_load_all(sys.stdin) if d], key=lambda d:(d["kind"],d["metadata"]["name"])), sort_keys=True))' >"$HM_TMP/expected.json"
hm_manifest_json "$REL" | jq -S 'sort_by(.kind,.metadata.name)' >"$HM_TMP/live.json"
jq -S . "$HM_TMP/expected.json" >"$HM_TMP/expected.s.json"
cmp -s "$HM_TMP/expected.s.json" "$HM_TMP/live.json" || hm_fail "The deployed objects differ from what the signed package renders — the release did not come from the signed artifact"

# Signing must have happened before the deploy (otherwise it was an unverified install).
"$HM_PYTHON" - "$pkg.prov" "$(hm_history_json "$REL" | jq -r '.[-1].updated')" <<'PY' || hm_fail "The release was deployed before the package was signed — it was not installed with verification"
import os, re, sys
from datetime import datetime
prov = os.path.getmtime(sys.argv[1])
s = re.sub(r"(\.\d{6})\d*", r"\1", sys.argv[2].strip())
s = re.sub(r" ?[A-Z]{3,4}$", "", s) if not re.search(r"[+-]\d\d:?\d\d$|Z$", s) else s
s = s.replace(" ", "T", 1) if "T" not in s else s
dep = datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
sys.exit(0 if dep + 1 >= prov else 1)
PY
hm_ok "Release matches the signed package and was deployed after signing"

hm_info "Checking the workload..."
hm_wait_rollout "deployment/$REL" "$NS" 90s
ready="$(hm_jsonpath "deployment/$REL" '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment $REL has ${ready:-0}/2 ready pods"
hm_pass "payments-gateway runs from a package whose signature you verified."
