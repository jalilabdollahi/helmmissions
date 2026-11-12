#!/bin/bash
set -uo pipefail
source "$HM_LIB"

repo=m9-repo-index-stale
URL="$HM_CHARTREPO_URL/$repo"
dir="$HM_CHARTREPO_DIR/$repo"

hm_hint_wait() { for _ in $(seq 1 15); do curl -fsS "$URL/index.yaml" 2>/dev/null | grep -q "tide-tracker-1.3.0" && return 0; sleep 1; done; return 1; }

hm_info "Reading the index served at $URL ..."
hm_hint_wait || hm_fail "The index served at the repository URL does not list tide-tracker 1.3.0"
curl -fsS "$URL/index.yaml" >"$HM_TMP/served.yaml" 2>/dev/null || hm_fail "Cannot download $URL/index.yaml"
"$HM_PYTHON" - "$HM_TMP/served.yaml" >"$HM_TMP/entries.txt" <<'PY' || hm_fail "The served index.yaml cannot be parsed"
import sys, yaml
idx = yaml.safe_load(open(sys.argv[1]))
for e in (idx.get("entries") or {}).get("tide-tracker", []):
    print(e["version"], e.get("digest", ""), e["urls"][0])
PY
for v in 1.1.0 1.2.0 1.3.0; do
  grep -q "^$v " "$HM_TMP/entries.txt" || hm_fail "The index no longer lists tide-tracker $v (versions listed: $(awk '{printf "%s ", $1}' "$HM_TMP/entries.txt"))"
done
while read -r v digest url; do
  base="$(basename "$url")"
  file="$(find "$dir" -name "$base" -type f 2>/dev/null | head -1)"
  [ -n "$file" ] || hm_fail "Index entry $v points at $url but no such tarball exists in the repository folder"
  [ "$(hm_sha256 "$file")" = "$digest" ] || hm_fail "Digest recorded for tide-tracker $v does not match its tarball"
done <"$HM_TMP/entries.txt"
hm_ok "Index lists 1.1.0, 1.2.0 and 1.3.0 with matching digests"

hm_info "Checking Helm can use the repository..."
helm repo list -o json 2>/dev/null | jq -e --arg u "$URL" 'any(.[]; .name=="hm-tides" and (.url|rtrimstr("/"))==$u)' >/dev/null \
  || hm_fail "Repository hm-tides is not configured for $URL"
helm repo update hm-tides >"$HM_TMP/update.txt" 2>&1 || hm_fail "helm repo update hm-tides fails" "$HM_TMP/update.txt"
mkdir -p "$HM_TMP/pull"
for v in 1.1.0 1.2.0 1.3.0; do
  helm pull hm-tides/tide-tracker --version "$v" -d "$HM_TMP/pull" >"$HM_TMP/pull.txt" 2>&1 || hm_fail "helm pull hm-tides/tide-tracker --version $v fails" "$HM_TMP/pull.txt"
done
hm_ok "All three versions download from hm-tides"

hm_info "Checking the release..."
hm_require_deployed tide-tracker
[ "$(hm_release_chart tide-tracker)" = "tide-tracker-1.3.0" ] || hm_fail "Release tide-tracker runs chart '$(hm_release_chart tide-tracker)', expected tide-tracker-1.3.0"
hm_wait_rollout deployment/tide-tracker "$NS" 90s
fh="$(hm_jsonpath deployment/tide-tracker '{.spec.template.spec.containers[0].env[0].value}')"
[ "$fh" = 48 ] || hm_fail "The running pods use FORECAST_HOURS=$fh — they are not on 1.3.0"
hm_pass "tide-tracker 1.3.0 is published and rolled out; older versions remain available."
