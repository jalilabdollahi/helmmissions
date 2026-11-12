#!/bin/bash
set -uo pipefail
source "$HM_LIB"

hm_info "Checking the releases..."
for s in ingest rollup alerts; do hm_require_deployed "telemetry-$s"; done

hm_info "Checking the pods..."
for s in ingest rollup alerts; do hm_wait_rollout "deployment/telemetry-$s" "$NS" 90s; done
for _ in $(seq 1 20); do
  total="$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=telemetry --no-headers | wc -l | tr -d ' ')"
  [ "$total" = "4" ] && break
  sleep 2
done
pend="$(kubectl get pods -n "$NS" --no-headers | grep -c Pending || true)"
[ "$pend" = "0" ] || hm_fail "$pend pod(s) are still Pending"
for s in ingest rollup alerts; do
  want=1; [ "$s" = alerts ] && want=2
  n="$(hm_pods_json "app.kubernetes.io/instance=telemetry-$s" | jq '[.[]|select(.status.containerStatuses[0].ready==true)]|length')"
  [ "$n" = "$want" ] || hm_fail "telemetry-$s has $n ready pods, expected $want"
done
hm_ok "All pods are scheduled and ready"

hm_info "Checking requests against the budget, and the workspace against the cluster..."
for s in ingest rollup alerts; do
  live="$(kubectl get deployment "telemetry-$s" -n "$NS" -o json)"
  echo "$live" | "$HM_PYTHON" -c '
import json, sys
def cpu(v):
    v = str(v); return float(v[:-1]) if v.endswith("m") else float(v) * 1000
def mem(v):
    v = str(v)
    for suf, mul in (("Ki", 1/1024), ("Mi", 1), ("Gi", 1024), ("Ti", 1024*1024)):
        if v.endswith(suf): return float(v[:-2]) * mul
    return float(v) / (1024 * 1024)
d = json.load(sys.stdin)
for c in d["spec"]["template"]["spec"]["containers"]:
    r = (c.get("resources") or {}).get("requests") or {}
    if "cpu" not in r or "memory" not in r:
        print("a container has no CPU or memory request"); sys.exit(1)
    if cpu(r["cpu"]) <= 0 or cpu(r["cpu"]) > 250: print("CPU request %sm is outside the 0-250m budget" % cpu(r["cpu"])); sys.exit(1)
    if mem(r["memory"]) <= 0 or mem(r["memory"]) > 512: print("memory request %sMi is outside the 0-512Mi budget" % mem(r["memory"])); sys.exit(1)
' >"$HM_TMP/budget.txt" 2>&1 || hm_fail "telemetry-$s: $(cat "$HM_TMP/budget.txt")"
  norm='[.[]|select(.kind=="Deployment")][0]|{rep:.spec.replicas,sel:(.spec.template.spec.nodeSelector//{}),aff:(.spec.template.spec.affinity//{}),req:.spec.template.spec.containers[0].resources.requests}'
  rendered="$(helm template "telemetry-$s" "$SANDBOX/telemetry" -n "$NS" -f "$SANDBOX/values/$s.yaml" 2>"$HM_TMP/render-err.txt" | "$HM_PYTHON" -c 'import json,sys,yaml; print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))' | jq -S "$norm")" || hm_fail "telemetry does not render with values/$s.yaml" "$HM_TMP/render-err.txt"
  relm="$(hm_manifest_json "telemetry-$s" | jq -S "$norm")"
  livej="$(echo "$live" | jq -S '{rep:.spec.replicas,sel:(.spec.template.spec.nodeSelector//{}),aff:(.spec.template.spec.affinity//{}),req:.spec.template.spec.containers[0].resources.requests}')"
  # normalise quantities (500m vs 0.5) by comparing only the strings the files render against the release record
  [ "$rendered" = "$relm" ] || hm_fail "values/$s.yaml would deploy something different from release telemetry-$s"
  [ "$(echo "$livej" | jq -c '.sel,.aff,.rep')" = "$(echo "$relm" | jq -c '.sel,.aff,.rep')" ] || hm_fail "The live Deployment telemetry-$s differs from its release record"
done
hm_ok "Requests within budget; workspace, release and live objects agree"

hm_info "Checking the services..."
for s in ingest rollup alerts; do
  ok=""
  for _ in 1 2 3 4; do
    hm_http_check "http://telemetry-$s/" >"$HM_TMP/$s.txt" 2>/dev/null
    grep -q "version=2.0" "$HM_TMP/$s.txt" && { ok=1; break; }
    sleep 3
  done
  [ -n "$ok" ] || hm_fail "telemetry-$s is not serving version 2.0" "$HM_TMP/$s.txt"
done
hm_pass "Version 2.0 is out and scheduled everywhere."
