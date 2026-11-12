#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHARTS=(ledger-api ledger-worker)
STD='["app.kubernetes.io/instance","app.kubernetes.io/managed-by","app.kubernetes.io/name","app.kubernetes.io/part-of","app.kubernetes.io/version","helm.sh/chart"]'

# keys_of JSON → for every object that has labels: "kind/name <sorted label keys>" lines for metadata and pod template
label_report() {
  jq -c '.[] | select(.kind=="Deployment" or .kind=="Service")
         | {k: (.kind+"/"+.metadata.name), keys: ((.metadata.labels // {}) | keys),
            pod: ((.spec.template.metadata.labels // null) | if . == null then null else keys end),
            partof: (.metadata.labels["app.kubernetes.io/part-of"] // ""),
            podpartof: (.spec.template.metadata.labels["app.kubernetes.io/part-of"] // "")}'
}

hm_info "Looking for the shared library chart..."
libdir_first=""
for c in "${CHARTS[@]}"; do
  dir="$SANDBOX/$c"
  [ -f "$dir/Chart.yaml" ] || hm_fail "$c/Chart.yaml is missing from the workspace"
  found=""
  while IFS= read -r repo; do
    [ -n "$repo" ] || continue
    p="$(cd "$dir" 2>/dev/null && cd "${repo#file://}" 2>/dev/null && pwd)" || continue
    if [ "$(hm_yaml_get "$p/Chart.yaml" type | jq -r '.')" = "library" ]; then found="$p"; break; fi
  done < <(hm_yaml_get "$dir/Chart.yaml" dependencies | jq -r '.[]? | .repository // empty | select(startswith("file://"))')
  [ -n "$found" ] || hm_fail "$c does not declare a dependency on a library chart (a file:// dependency whose Chart.yaml says type: library)"
  if [ -z "$libdir_first" ]; then libdir_first="$found"; elif [ "$libdir_first" != "$found" ]; then
    hm_fail "ledger-api and ledger-worker use different library charts ($libdir_first vs $found) — the point is ONE shared definition"
  fi
done
hm_ok "Both charts depend on the library chart $(basename "$libdir_first") (type: library)"

hm_info "Rendering both charts and comparing label sets..."
for c in "${CHARTS[@]}"; do
  out="$(hm_render_json "$SANDBOX/$c")" || true
  [ -n "$out" ] && [ "$out" != "[]" ] || hm_fail "helm template $c fails" "$HM_TMP/render-err.txt"
  bad="$(echo "$out" | label_report | jq -c --argjson std "$STD" 'select(.keys != $std or (.pod != null and .pod != $std) or .partof != "ledger" or (.pod != null and .podpartof != "ledger"))')"
  [ -z "$bad" ] || hm_fail "$c renders objects whose labels do not match the standard in README.txt: $(echo "$bad" | head -1 | jq -c '{object: .k, labels: .keys, podLabels: .pod, partOf: .partof}')"
done
hm_ok "Rendered labels match the standard and are identical across both charts"

hm_info "Proving the labels really come from the library (tamper test on a temporary copy)..."
for c in "${CHARTS[@]}"; do
  t="$HM_TMP/t-$c"; rm -rf "$t"; cp -R "$SANDBOX/$c" "$t"
  while IFS= read -r dep; do
    name="$(echo "$dep" | jq -r '.name')"; repo="$(echo "$dep" | jq -r '.repository // ""')"
    case "$repo" in file://*)
      p="$(cd "$SANDBOX/$c" && cd "${repo#file://}" && pwd)" || continue
      [ "$(hm_yaml_get "$p/Chart.yaml" type | jq -r '.')" = "library" ] || continue
      rm -rf "$t/charts/$name" "$t"/charts/"$name"-*.tgz; mkdir -p "$t/charts"; cp -R "$p" "$t/charts/$name"
      find "$t/charts/$name" -type f -exec sed -i.bak 's#app\.kubernetes\.io/part-of#tampered.example/part-of#g' {} + 2>/dev/null
      find "$t/charts/$name" -name '*.bak' -delete ;;
    esac
  done < <(hm_yaml_get "$SANDBOX/$c/Chart.yaml" dependencies | jq -c '.[]?')
  out="$(hm_render_json "$t")" || true
  miss="$(echo "$out" | jq -c '[.[] | select(.kind=="Deployment" or .kind=="Service") | select((.metadata.labels["tampered.example/part-of"] // "") != "ledger")] | length' 2>/dev/null || echo 99)"
  [ "$miss" = 0 ] || hm_fail "$c still carries its own copy of the label logic — changing the library did not change its rendered labels"
done
hm_ok "Rendered labels follow the library"

hm_info "Checking the releases..."
for c in "${CHARTS[@]}"; do
  hm_require_deployed "$c"
  rev="$(hm_release_revision "$c")"
  [ "${rev:-1}" -ge 2 ] || hm_fail "Release $c is still at revision ${rev:-1} — the shared labels have not been rolled out"
  hm_wait_rollout "deployment/$c" "$NS" 90s
  live="$(kubectl get deploy "$c" -n "$NS" -o json | jq -c --argjson std "$STD" '[(.metadata.labels|keys), (.spec.template.metadata.labels|keys)] | all(. == $std)')"
  [ "$live" = true ] || hm_fail "The live Deployment $c does not carry exactly the standard label keys yet"
  po="$(kubectl get deploy "$c" -n "$NS" -o jsonpath='{.metadata.labels.app\.kubernetes\.io/part-of}')"
  [ "$po" = ledger ] || hm_fail "Live Deployment $c has part-of='$po', expected 'ledger'"
done
hm_pass "ledger-api and ledger-worker share one label definition from the library."
