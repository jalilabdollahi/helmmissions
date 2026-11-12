#!/bin/bash
set -uo pipefail
source "$HM_LIB"

rel_ns() { echo "helmissions-$1"; }
cs() { jq -r '.[]|select(.kind=="ClusterRole" or .kind=="ClusterRoleBinding" or .kind=="PriorityClass")|"\(.kind)/\(.metadata.name)"'; }

hm_info "Checking the releases..."
for r in team-a team-b; do hm_require_deployed "$r" "$(rel_ns "$r")"; done

hm_info "Checking that no cluster-scoped object is shared..."
: >"$HM_TMP/all.txt"
for r in team-a team-b; do
  ns="$(rel_ns "$r")"
  hm_manifest_json "$r" "$ns" | cs >"$HM_TMP/$r.cs"
  [ -s "$HM_TMP/$r.cs" ] || hm_fail "Release $r contains no cluster-scoped objects (the collector needs its ClusterRole)"
  while read -r obj; do
    name="${obj#*/}"
    case "$name" in *"$r"*|*"$ns"*) ;; *) hm_fail "Release $r has a cluster-scoped object ($obj) whose name is not scoped to the release or its namespace" ;; esac
    kind="${obj%%/*}"
    own="$(kubectl get "$kind" "$name" -o json 2>/dev/null | jq -r '.metadata.annotations["meta.helm.sh/release-name"] + "/" + .metadata.annotations["meta.helm.sh/release-namespace"]')"
    [ "$own" = "$r/$ns" ] || hm_fail "$obj is not owned by release $r in $ns (owner: '$own')"
  done <"$HM_TMP/$r.cs"
  cat "$HM_TMP/$r.cs" >>"$HM_TMP/all.txt"
done
dups="$(sort "$HM_TMP/all.txt" | uniq -d)"
[ -z "$dups" ] || hm_fail "Both releases still manage the same cluster-scoped object: $dups"
hm_ok "Each release owns its own cluster-scoped objects"

hm_info "Checking the chart renders release-scoped names for any release..."
for pair in "x-one:helmissions-ns-one" "x-two:helmissions-ns-two"; do
  helm template "${pair%%:*}" "$SANDBOX/collector" -n "${pair##*:}" 2>"$HM_TMP/t.err" | "$HM_PYTHON" -c '
import json, sys, yaml
print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))' >"$HM_TMP/${pair%%:*}.json" || hm_fail "The chart does not render"
  cs <"$HM_TMP/${pair%%:*}.json" | sort >"$HM_TMP/${pair%%:*}.names"
  [ -s "$HM_TMP/${pair%%:*}.names" ] || hm_fail "The workspace chart renders no cluster-scoped objects" "$HM_TMP/t.err"
  jq -e --arg ns "${pair##*:}" '[.[]|select(.kind=="ClusterRoleBinding")][0].subjects[0].namespace == $ns' "$HM_TMP/${pair%%:*}.json" >/dev/null \
    || hm_fail "The workspace chart's ClusterRoleBinding does not point at the ServiceAccount of the release's own namespace"
done
[ -z "$(comm -12 "$HM_TMP/x-one.names" "$HM_TMP/x-two.names")" ] || hm_fail "The workspace chart renders the same cluster-scoped names for two different releases"
hm_ok "The chart is multi-tenant safe"

hm_info "Checking both collectors really have access..."
for r in team-a team-b; do
  ns="$(rel_ns "$r")"
  hm_wait_rollout "deployment/$r-collector" "$ns" 90s
  [ "$(kubectl auth can-i list pods --all-namespaces --as="system:serviceaccount:$ns:collector")" = "yes" ] || hm_fail "ServiceAccount collector in $ns is not allowed to list pods"
  ok=""
  for _ in 1 2 3 4 5 6; do
    hm_http_check "http://$r-collector/status" "$ns" >"$HM_TMP/s-$r.txt" 2>/dev/null
    grep -qx "pods-api=200" "$HM_TMP/s-$r.txt" && { ok=1; break; }
    sleep 3
  done
  [ -n "$ok" ] || hm_fail "The status page of $r-collector does not report pods-api=200" "$HM_TMP/s-$r.txt"
done
hm_pass "Two teams, two collectors, no shared cluster-scoped objects."
