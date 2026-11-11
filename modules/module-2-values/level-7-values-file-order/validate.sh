#!/bin/bash
set -uo pipefail
source "$HM_LIB"
PNS=helmissions-prod

hm_require_deployed checkout "$PNS"

hm_info "Checking the live configuration..."
vals="$(hm_all_values checkout "$PNS")"
[ "$(echo "$vals" | jq -r .replicaCount)" = "3" ] || hm_fail "checkout is configured with replicaCount=$(echo "$vals" | jq -r .replicaCount), production needs 3"
env="$(kubectl get deploy checkout -n "$PNS" -o json | jq -c '[.spec.template.spec.containers[0].env[] | {(.name): .value}] | add')"
[ "$(echo "$env" | jq -r .LOG_LEVEL)" = "warn" ] || hm_fail "LOG_LEVEL in production is '$(echo "$env" | jq -r .LOG_LEVEL)', expected warn"
[ "$(echo "$env" | jq -r .REGION)" = "eu-west-1" ] || hm_fail "REGION is '$(echo "$env" | jq -r .REGION)' - the shared base values are no longer applied"
kubectl rollout status deployment/checkout -n "$PNS" --timeout=90s >"$HM_TMP/r.txt" 2>&1 || hm_fail "checkout did not roll out" "$HM_TMP/r.txt"
ready="$(hm_jsonpath deployment/checkout '{.status.readyReplicas}' "$PNS")"
[ "${ready:-0}" = "3" ] || hm_fail "Only ${ready:-0}/3 replicas are ready"
hm_ok "3 replicas, LOG_LEVEL=warn, REGION from base"

hm_info "Checking deploy.sh..."
[ -f "$SANDBOX/deploy.sh" ] || hm_fail "deploy.sh is missing"
"$HM_PYTHON" - "$SANDBOX/deploy.sh" <<'PY' || hm_fail "deploy.sh still applies the values files in an order where values-base.yaml overrides values-prod.yaml (or does not deploy checkout to helmissions-prod with both files)"
import re, sys
text = "\n".join(l for l in open(sys.argv[1]).read().splitlines() if not l.lstrip().startswith("#"))
base = [m.start() for m in re.finditer(r"values-base\.yaml", text)]
prod = [m.start() for m in re.finditer(r"values-prod\.yaml", text)]
ok = base and prod and max(base) < min(prod) and "helmissions-prod" in text and re.search(r"\bcheckout\b", text)
sys.exit(0 if ok else 1)
PY
hm_pass "Production runs with production values, and deploy.sh keeps it that way."
