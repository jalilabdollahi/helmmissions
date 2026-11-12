# shellcheck shell=bash
# HelmMissions helper library — sourced by every level's setup.sh / validate.sh / solve.sh:
#
#   source "$HM_LIB"
#
# Environment provided by the engine (and by scripts/test_levels.py):
#   NS          primary namespace (always "helmissions" in the game)
#   LEVEL_DIR   absolute path of the level directory (mission.yaml, assets/, solution/ ...)
#   SANDBOX     absolute path of the player's workspace (copy of the level's broken/ dir)
#   HM_LIB      this file
#   HM_PYTHON   python3 interpreter that has PyYAML installed
#   HM_ROOT     repository root
#   HM_REGISTRY         host:port of the shared OCI registry   (default localhost:5001)
#   HM_CHARTREPO_DIR    directory served over HTTP as a classic chart repo
#   HM_CHARTREPO_URL    base URL of that directory              (default http://localhost:8879)
# The working directory is $SANDBOX.

: "${NS:=helmissions}"
: "${HM_PYTHON:=python3}"
: "${HM_REGISTRY:=localhost:5001}"
: "${HM_CHARTREPO_URL:=http://localhost:8879}"
if [ -z "${HM_ROOT:-}" ]; then
  HM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
: "${HM_CHARTREPO_DIR:=$HM_ROOT/.hm-shared/chartrepo}"
export NS HM_PYTHON HM_REGISTRY HM_CHARTREPO_URL HM_CHARTREPO_DIR HM_ROOT

# ── output ───────────────────────────────────────────────────────────────────
hm_info() { echo "🔍 $*"; }
hm_ok()   { echo "✅ $*"; }
hm_warn() { echo "⚠️  $*"; }
# hm_fail "message" [file-with-details]  → prints and exits 1
hm_fail() {
  echo "❌ $1"
  if [ -n "${2:-}" ] && [ -s "$2" ]; then sed 's/^/   │ /' "$2" | head -n 25; fi
  exit 1
}
hm_pass() { echo "✅ ${1:-Mission complete!}"; exit 0; }

# ── temp files (auto-removed on exit) ────────────────────────────────────────
HM_TMP="$(mktemp -d "${TMPDIR:-/tmp}/helmissions.XXXXXX")"
trap 'rm -rf "$HM_TMP"' EXIT

# ── helm release helpers ─────────────────────────────────────────────────────
# hm_release_status REL [NS] → deployed|failed|pending-upgrade|... (empty if missing)
hm_release_status() {
  helm status "$1" -n "${2:-$NS}" -o json 2>/dev/null | jq -r '.info.status // empty' 2>/dev/null || true
}
# hm_release_revision REL [NS] → current revision number (empty if missing)
hm_release_revision() {
  helm status "$1" -n "${2:-$NS}" -o json 2>/dev/null | jq -r '.version // empty' 2>/dev/null || true
}
# hm_release_chart REL [NS] → "<chart>-<version>" of the current revision, e.g. webapp-0.1.0
#   (works on Helm 3 and 4 — Helm 4's `helm status -o json` no longer includes the chart)
hm_release_chart() {
  helm history "$1" -n "${2:-$NS}" --max 1 -o json 2>/dev/null | jq -r '.[-1].chart // empty' 2>/dev/null || true
}
# hm_release_app_version REL [NS]
hm_release_app_version() {
  helm history "$1" -n "${2:-$NS}" --max 1 -o json 2>/dev/null | jq -r '.[-1].app_version // empty' 2>/dev/null || true
}
# hm_release_exists REL [NS]
hm_release_exists() { [ -n "$(hm_release_status "$1" "${2:-$NS}")" ]; }
# hm_require_deployed REL [NS] → fails the check unless the release is deployed
hm_require_deployed() {
  local st; st="$(hm_release_status "$1" "${2:-$NS}")"
  [ -n "$st" ] || hm_fail "Release '$1' not found in namespace '${2:-$NS}'"
  [ "$st" = "deployed" ] || hm_fail "Release '$1' is '$st', expected 'deployed'"
  hm_ok "Release '$1' is deployed"
}
# hm_history_json REL [NS] → helm history as JSON array
hm_history_json() { helm history "$1" -n "${2:-$NS}" --max 256 -o json 2>/dev/null || echo '[]'; }
# hm_user_values REL [NS] → user-supplied values as JSON ({} if none)
hm_user_values() {
  local out; out="$(helm get values "$1" -n "${2:-$NS}" -o json 2>/dev/null || true)"
  [ -z "$out" ] || [ "$out" = "null" ] && out='{}'
  echo "$out"
}
# hm_all_values REL [NS] → computed values as JSON
hm_all_values() { helm get values "$1" -n "${2:-$NS}" --all -o json 2>/dev/null || echo '{}'; }

# hm_release_description REL [NS] → description of the latest revision ("Rollback to 2", "Upgrade complete"...)
hm_release_description() { hm_history_json "$1" "${2:-$NS}" | jq -r '.[-1].description // empty'; }
# hm_assert_status REL STATUS [NS] → for setup.sh: exit 1 unless the release is in STATUS
hm_assert_status() {
  local st; st="$(hm_release_status "$1" "${3:-$NS}")"
  [ "$st" = "$2" ] || { echo "setup: release $1 is '${st:-missing}', expected '$2' — scenario not reached"; exit 1; }
}
# Version-neutral flags: Helm 4 renamed --atomic and --force
hm_flag_rollback_on_failure() { [ "$(hm_helm_major)" -ge 4 ] && echo "--rollback-on-failure" || echo "--atomic"; }
hm_flag_force_replace() { [ "$(hm_helm_major)" -ge 4 ] && echo "--force-replace" || echo "--force"; }

# ── kubernetes helpers ───────────────────────────────────────────────────────
# hm_wait_rollout KIND/NAME [NS] [TIMEOUT]
hm_wait_rollout() {
  kubectl rollout status "$1" -n "${2:-$NS}" --timeout="${3:-90s}" >"$HM_TMP/rollout.txt" 2>&1 \
    || hm_fail "$1 did not become ready" "$HM_TMP/rollout.txt"
  hm_ok "$1 is ready"
}
# hm_wait_pods_ready SELECTOR [NS] [TIMEOUT]
hm_wait_pods_ready() {
  kubectl wait pod -l "$1" -n "${2:-$NS}" --for=condition=Ready --timeout="${3:-90s}" >"$HM_TMP/wait.txt" 2>&1 \
    || hm_fail "Pods matching '$1' are not Ready" "$HM_TMP/wait.txt"
}
# hm_jsonpath KIND/NAME JSONPATH [NS] → value (empty if missing)
hm_jsonpath() { kubectl get "$1" -n "${3:-$NS}" -o "jsonpath=$2" 2>/dev/null || true; }
# hm_endpoints_count SERVICE [NS] → number of ready endpoint addresses
hm_endpoints_count() {
  kubectl get endpointslices -n "${2:-$NS}" -l "kubernetes.io/service-name=$1" -o json 2>/dev/null \
    | jq '[.items[].endpoints[]? | select(.conditions.ready != false)] | length' 2>/dev/null || echo 0
}
# hm_http_check URL [NS] [TRIES] → curl URL from a one-shot pod inside the namespace, prints the body;
#   retries (default 5 tries, 3s apart) because new Services/endpoints take a moment to become reachable
hm_http_check() {
  local tries="${3:-5}" n out
  for n in $(seq 1 "$tries"); do
    if out="$(_hm_http_once "$1" "${2:-$NS}")"; then
      printf '%s\n' "$out"
      return 0
    fi
    [ "$n" -lt "$tries" ] && sleep 3
  done
  printf '%s\n' "$out" >&2
  return 1
}
# hm_wait_old_pods_gone SELECTOR [NS] [TIMEOUT_SECONDS] → wait until no terminating pods match SELECTOR
#   (after a rollout, terminating pods can still answer through the Service for a few seconds)
hm_wait_old_pods_gone() {
  local i
  for i in $(seq 1 "${3:-60}"); do
    [ "$(kubectl get pods -n "${2:-$NS}" -l "$1" -o json 2>/dev/null \
         | jq '[.items[] | select(.metadata.deletionTimestamp != null)] | length' 2>/dev/null || echo 0)" = "0" ] && return 0
    sleep 1
  done
  return 1
}
_hm_http_once() {
  local name="hm-probe-$RANDOM" ns="${2:-$NS}" phase="" i
  kubectl run "$name" -n "$ns" --image=curlimages/curl:8.10.1 --image-pull-policy=IfNotPresent --restart=Never \
    --labels=helmissions.io/probe=true --command -- curl -fsS --max-time 5 "$1" >/dev/null 2>&1 || return 1
  for i in $(seq 1 40); do
    phase="$(kubectl get pod "$name" -n "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    [ "$phase" = "Succeeded" ] || [ "$phase" = "Failed" ] && break
    sleep 1
  done
  local rc=1; [ "$phase" = "Succeeded" ] && rc=0
  kubectl logs pod/"$name" -n "$ns" 2>/dev/null
  kubectl delete pod/"$name" -n "$ns" --now --wait=false >/dev/null 2>&1 || true
  return $rc
}

# hm_pods_json SELECTOR [NS] → JSON array of pods matching SELECTOR that are not terminating
hm_pods_json() {
  kubectl get pods -n "${2:-$NS}" -l "$1" -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp == null)]' 2>/dev/null || echo '[]'
}
# hm_sha256 FILE|- → hex sha256 (portable: uses python)
hm_sha256() {
  "$HM_PYTHON" -c 'import hashlib,sys; d=(sys.stdin.buffer if sys.argv[1]=="-" else open(sys.argv[1],"rb")).read(); print(hashlib.sha256(d).hexdigest())' "${1:--}"
}

# ── YAML helpers (PyYAML via $HM_PYTHON) ─────────────────────────────────────
# hm_yaml_get FILE dotted.path → value as JSON (null if missing). Lists: a.b.0.c
hm_yaml_get() {
  "$HM_PYTHON" - "$1" "$2" <<'PY'
import json, sys, yaml
try:
    docs = list(yaml.safe_load_all(open(sys.argv[1], encoding="utf-8")))
except Exception as exc:  # unparsable file
    print("null"); sys.exit(0)
node = docs[0] if docs else None
for part in [p for p in sys.argv[2].split(".") if p]:
    if isinstance(node, list) and part.isdigit() and int(part) < len(node):
        node = node[int(part)]
    elif isinstance(node, dict) and part in node:
        node = node[part]
    else:
        node = None
        break
print(json.dumps(node))
PY
}
# hm_yaml_valid FILE → exit 0 when FILE parses as YAML
hm_yaml_valid() {
  "$HM_PYTHON" -c 'import sys,yaml; list(yaml.safe_load_all(open(sys.argv[1], encoding="utf-8")))' "$1" >/dev/null 2>&1
}
# hm_render_json CHART [helm template args...] → rendered manifests as a JSON array of objects
hm_render_json() {
  local chart="$1"; shift
  helm template hm-render "$chart" -n "$NS" "$@" 2>"$HM_TMP/render-err.txt" | "$HM_PYTHON" -c '
import json, sys, yaml
print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))'
}
# hm_manifest_json REL [NS] → live release manifest as a JSON array of objects
hm_manifest_json() {
  helm get manifest "$1" -n "${2:-$NS}" 2>/dev/null | "$HM_PYTHON" -c '
import json, sys, yaml
print(json.dumps([d for d in yaml.safe_load_all(sys.stdin) if d]))'
}

# ── shared registry / chart repo ─────────────────────────────────────────────
hm_registry_up() {
  if ! curl -fsS "http://${HM_REGISTRY}/v2/" >/dev/null 2>&1; then
    bash "$HM_ROOT/scripts/cluster.sh" registry >/dev/null
  fi
}
# hm_chartrepo_path NAME → creates and prints $HM_CHARTREPO_DIR/NAME (served at $HM_CHARTREPO_URL/NAME)
hm_chartrepo_path() {
  hm_registry_up
  mkdir -p "$HM_CHARTREPO_DIR/$1"
  echo "$HM_CHARTREPO_DIR/$1"
}

# ── helm version ─────────────────────────────────────────────────────────────
# hm_helm_major → 3 or 4
hm_helm_major() { helm version --short 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'; }
