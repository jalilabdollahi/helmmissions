#!/bin/bash
set -uo pipefail
source "$HM_LIB"

PLUGIN="$SANDBOX/hm-audit"
[ -f "$PLUGIN/plugin.yaml" ] || hm_fail "hm-audit/plugin.yaml is missing from the workspace"

hm_info "Checking the installed plugin..."
line="$(helm plugin list 2>/dev/null | awk '$1=="hm-audit"')"
[ -n "$line" ] || hm_fail "Plugin hm-audit is not installed (helm plugin list)"
echo "$line" | awk '{print $3}' | grep -qx 'cli/v1' || hm_fail "Plugin hm-audit is installed but is not a cli/v1 plugin: $line"
helm hm-audit checkout -n "$NS" >"$HM_TMP/audit.txt" 2>&1 \
  || hm_fail "helm hm-audit checkout fails" "$HM_TMP/audit.txt"
grep -q 'containers=2 missing_limits=1' "$HM_TMP/audit.txt" || hm_fail "helm hm-audit ran but did not report containers=2 missing_limits=1" "$HM_TMP/audit.txt"
grep -q 'metrics-exporter' "$HM_TMP/audit.txt" || hm_fail "The audit does not name the container without limits" "$HM_TMP/audit.txt"
hm_ok "helm hm-audit checkout works"

hm_info "Proving the plugin installs from scratch (isolated plugin directory)..."
copy="$HM_TMP/src/hm-audit"; mkdir -p "$HM_TMP/src" "$HM_TMP/data/plugins"
cp -R "$PLUGIN" "$copy"
find "$copy" -maxdepth 1 -name rules.env -delete
HELM_DATA_HOME="$HM_TMP/data" HELM_PLUGINS="$HM_TMP/data/plugins" helm plugin install "$copy" >"$HM_TMP/clean.txt" 2>&1 \
  || hm_fail "A clean 'helm plugin install ./hm-audit' still fails" "$HM_TMP/clean.txt"
HELM_DATA_HOME="$HM_TMP/data" HELM_PLUGINS="$HM_TMP/data/plugins" helm hm-audit checkout -n "$NS" >"$HM_TMP/clean-run.txt" 2>&1 \
  || hm_fail "A freshly installed hm-audit does not run" "$HM_TMP/clean-run.txt"
grep -q 'missing_limits=1' "$HM_TMP/clean-run.txt" || hm_fail "A freshly installed hm-audit reports unexpected output" "$HM_TMP/clean-run.txt"
hm_pass "hm-audit installs cleanly and audits the checkout release."
