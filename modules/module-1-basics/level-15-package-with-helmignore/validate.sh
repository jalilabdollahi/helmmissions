#!/bin/bash
set -uo pipefail
source "$HM_LIB"

PKG="$SANDBOX/dist/reports-1.1.0.tgz"

hm_info "Checking the package..."
[ -f "$PKG" ] || hm_fail "dist/reports-1.1.0.tgz does not exist"
tar tzf "$PKG" >"$HM_TMP/files.txt" 2>/dev/null || hm_fail "dist/reports-1.1.0.tgz is not a valid archive"
for need in reports/Chart.yaml reports/values.yaml reports/templates/deployment.yaml reports/templates/service.yaml reports/templates/configmap.yaml; do
  grep -qx "$need" "$HM_TMP/files.txt" || hm_fail "The package is missing $need"
done
grep -E 'secrets\.local\.env|\.bak$|/tmp/|/tmp$' "$HM_TMP/files.txt" >"$HM_TMP/junk.txt" || true
if [ -s "$HM_TMP/junk.txt" ]; then
  hm_fail "The package contains local-only files that must not ship:" "$HM_TMP/junk.txt"
fi
hm_ok "Package contains only chart files ($(wc -l <"$HM_TMP/files.txt" | tr -d ' ') entries)"

hm_info "Checking the release..."
hm_require_deployed reports
chart="$(hm_release_chart reports)"
[ "$chart" = "reports-1.1.0" ] || hm_fail "Release reports runs chart '$chart', expected reports-1.1.0"
hm_wait_rollout deployment/reports "$NS" 90s
[ "$(hm_endpoints_count reports)" -ge 1 ] || hm_fail "Service reports has no ready endpoints"

hm_pass "reports 1.1.0 is packaged cleanly and deployed from the archive."
