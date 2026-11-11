#!/bin/bash
set -uo pipefail
source "$HM_LIB"

WANT="shop-frontend"
SCRIPT="$SANDBOX/deploy.sh"

hm_info "Checking the release name used by deploy.sh..."
[ -f "$SCRIPT" ] || hm_fail "deploy.sh is missing from the workspace"

# Run deploy.sh against a fake `helm` that only records its arguments, so we learn the release
# name the script would use — no matter how the script builds it (literal, variable, ...).
mkdir -p "$HM_TMP/shim"
cat >"$HM_TMP/shim/helm" <<'SH'
#!/bin/bash
echo "$@" >>"$HM_SHIM_LOG"
exit 0
SH
chmod +x "$HM_TMP/shim/helm"
export HM_SHIM_LOG="$HM_TMP/helm-calls.txt"; : >"$HM_SHIM_LOG"
( cd "$SANDBOX" && PATH="$HM_TMP/shim:$PATH" bash "$SCRIPT" >/dev/null 2>&1 ) || true

used="$("$HM_PYTHON" - "$HM_SHIM_LOG" <<'PY'
import sys
for line in open(sys.argv[1]):
    toks = line.split()
    if toks and toks[0] in ("install", "upgrade"):
        skip = False
        for t in toks[1:]:
            if skip: skip = False; continue
            if t in ("-n", "--namespace", "-f", "--values", "--set", "--timeout", "--version"):
                skip = True; continue
            if t.startswith("-"): continue
            print(t); sys.exit(0)
PY
)"
[ -n "$used" ] || hm_fail "deploy.sh no longer runs 'helm install' or 'helm upgrade'"
echo "$used" | grep -Eq '^[a-z0-9]([-a-z0-9]*[a-z0-9])?$' \
  || hm_fail "deploy.sh still uses the release name '$used', which Helm rejects"
[ "$used" = "$WANT" ] || hm_fail "deploy.sh uses release name '$used' — the shop team's dashboards expect '$WANT'"
hm_ok "deploy.sh uses the valid release name '$used'"

hm_info "Checking the release..."
hm_require_deployed "$WANT"
chart="$(hm_release_chart "$WANT")"
case "$chart" in storefront-*) ;; *) hm_fail "Release $WANT runs chart '$chart', expected the storefront chart" ;; esac

hm_wait_rollout "deployment/$WANT" "$NS" 90s
ready="$(hm_jsonpath "deployment/$WANT" '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment $WANT has ${ready:-0}/2 ready pods"
[ "$(hm_endpoints_count "$WANT")" -ge 2 ] || hm_fail "Service $WANT has no ready endpoints"

hm_pass "shop-frontend is live and deploy.sh now works for everyone."
