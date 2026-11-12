#!/bin/bash
# helm hm-audit RELEASE [-n NAMESPACE]
set -euo pipefail

rel=""; ns="${HELM_NAMESPACE:-default}"
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--namespace) ns="$2"; shift 2 ;;
    *) rel="$1"; shift ;;
  esac
done
[ -n "$rel" ] || { echo "usage: helm hm-audit RELEASE [-n NAMESPACE]" >&2; exit 2; }

if [ ! -f "$HELM_PLUGIN_DIR/rules.env" ]; then
  echo "hm-audit: rules.env is missing — the install hook did not run; reinstall the plugin" >&2
  exit 1
fi
# shellcheck disable=SC1091
source "$HELM_PLUGIN_DIR/rules.env"

kubectl get deployments -n "$ns" -l "app.kubernetes.io/instance=$rel" -o json | jq -r --arg rel "$rel" --arg ns "$ns" --arg req "${REQUIRE_LIMITS:-1}" '
  [.items[] | .metadata.name as $d | .spec.template.spec.containers[] | {d: $d, c: .name, lim: ((.resources.limits // {}) | length)}] as $all
  | "hm-audit: release \($rel) in \($ns)",
    ($all[] | select($req == "1" and .lim == 0) | "  no limits: \(.d)/\(.c)"),
    "containers=\($all | length) missing_limits=\([$all[] | select($req == "1" and .lim == 0)] | length)"'
