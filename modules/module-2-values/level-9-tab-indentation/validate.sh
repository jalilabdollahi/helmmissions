#!/bin/bash
set -uo pipefail
source "$HM_LIB"

V="$SANDBOX/audit-log/values.yaml"
[ -f "$V" ] || hm_fail "audit-log/values.yaml is missing"

hm_info "Checking values.yaml..."
if grep -q "$(printf '\t')" "$V"; then hm_fail "values.yaml still contains tab characters (line $(grep -n "$(printf '\t')" "$V" | head -1 | cut -d: -f1))"; fi
hm_yaml_valid "$V" || hm_fail "values.yaml is not valid YAML yet"
"$HM_PYTHON" - "$V" <<'PY' || hm_fail "values.yaml no longer carries the intended audit settings (retention 90, siem.corp.example:6514, tls on)"
import sys, yaml
a = (yaml.safe_load(open(sys.argv[1])) or {}).get("audit") or {}
s = a.get("sink") or {}
ok = a.get("retentionDays") == 90 and s.get("host") == "siem.corp.example" and s.get("port") == 6514 and s.get("tls") is True
sys.exit(0 if ok else 1)
PY
helm lint "$SANDBOX/audit-log" >"$HM_TMP/lint.txt" 2>&1 || hm_fail "helm lint reports errors" "$HM_TMP/lint.txt"
hm_ok "values.yaml is clean"

hm_require_deployed audit-log
hm_wait_rollout deployment/audit-log "$NS" 90s
ready="$(hm_jsonpath deployment/audit-log '{.status.readyReplicas}')"
[ "${ready:-0}" -ge 2 ] || hm_fail "Deployment audit-log has ${ready:-0}/2 ready pods"
conf="$(kubectl get configmap audit-log-config -n "$NS" -o jsonpath='{.data.audit\.conf}')"
for want in retention_days=90 sink_host=siem.corp.example sink_port=6514 sink_tls=true; do
  echo "$conf" | grep -qx "$want" || hm_fail "Deployed audit.conf is missing '$want'"
done
hm_pass "audit-log runs with the compliance settings."
