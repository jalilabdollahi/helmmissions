#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/payments"
[ -f "$CHART/Chart.yaml" ] || hm_fail "payments/Chart.yaml is missing from the workspace"
svcsel() { jq -S -c '[.[] | select(.kind=="Service") | .spec.selector] | first // {}'; }
depsel() { jq -S -c '[.[] | select(.kind=="Deployment") | .spec.selector.matchLabels] | first // {}'; }
podlabels() { jq -S -c '[.[] | select(.kind=="Deployment") | .spec.template.metadata.labels] | first // {}'; }

hm_info "Rendering the chart under release name 'zz9'..."
helm template zz9 "$CHART" -n "$NS" 2>"$HM_TMP/err.txt" | "$HM_PYTHON" -c 'import json,sys,yaml; print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))' >"$HM_TMP/r.json" || true
[ "$(jq length "$HM_TMP/r.json" 2>/dev/null || echo 0)" -gt 0 ] || hm_fail "helm template fails" "$HM_TMP/err.txt"
s="$(svcsel <"$HM_TMP/r.json")"; d="$(depsel <"$HM_TMP/r.json")"; p="$(podlabels <"$HM_TMP/r.json")"
[ "$s" = "$d" ] || hm_fail "Service selector $s differs from the Deployment selector $d"
echo "$s" | jq -e 'to_entries | map(select(.value == "zz9")) | length > 0' >/dev/null || hm_fail "The selector is not specific to the release name (selector: $s)"
echo "$p" | jq -e --argjson s "$s" 'contains($s)' >/dev/null || hm_fail "The pod labels do not contain the selector"
hm_ok "Service and Deployment share one release-specific selector"

hm_info "Checking the release..."
hm_require_deployed payments
rev="$(hm_release_revision payments)"
[ "${rev:-0}" -ge 2 ] || hm_fail "Release payments is still at revision ${rev:-?} - the fixed chart was never deployed"
live="$(kubectl get svc payments -n "$NS" -o json | jq -S -c '.spec.selector')"
[ "$live" = "$(kubectl get deploy payments -n "$NS" -o json | jq -S -c '.spec.selector.matchLabels')" ] || hm_fail "Live Service selector $live differs from the Deployment selector"
hm_wait_rollout deployment/payments "$NS" 90s
for _ in $(seq 1 15); do [ "$(hm_endpoints_count payments)" -ge 2 ] && break; sleep 2; done
[ "$(hm_endpoints_count payments)" -ge 2 ] || hm_fail "Service payments has $(hm_endpoints_count payments) ready endpoints, expected 2"

hm_pass "payments has endpoints again."
