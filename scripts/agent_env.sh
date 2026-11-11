# shellcheck shell=bash
# Isolated environment for a level author / tester working in parallel with others.
#
#   source scripts/agent_env.sh <slot>      # slot = 1..4
#
# Gives each slot its own kind cluster (hm-w<slot>), kubeconfig, Helm config/cache/data
# dirs and sandbox, so several authors can run scripts/test_levels.py at the same time.
# The local OCI registry (localhost:5001) and chart repo (localhost:8879) are shared.
_slot="${1:?usage: source scripts/agent_env.sh <slot>}"
if [ -n "${ZSH_VERSION:-}" ]; then eval '_src="${(%):-%x}"'; else _src="${BASH_SOURCE[0]}"; fi
_root="$(cd "$(dirname "$_src")/.." && pwd)"
_state="$_root/.hm-shared/agents/w${_slot}"
mkdir -p "$_state"/{helm-config,helm-cache,helm-data,sandbox}
export HELMISSIONS_CONTEXT="kind-hm-w${_slot}"
export KUBECONFIG="$_state/kubeconfig"
export HELM_CONFIG_HOME="$_state/helm-config"
export HELM_CACHE_HOME="$_state/helm-cache"
export HELM_DATA_HOME="$_state/helm-data"
export HELMISSIONS_SANDBOX_ROOT="$_state/sandbox"
if ! kind get clusters 2>/dev/null | grep -qx "hm-w${_slot}"; then
  KUBECONFIG="$KUBECONFIG" bash "$_root/scripts/cluster.sh" create "hm-w${_slot}" >"$_state/cluster-create.log" 2>&1 \
    || { echo "cluster creation failed, see $_state/cluster-create.log"; return 1; }
fi
[ -s "$KUBECONFIG" ] || kind get kubeconfig --name "hm-w${_slot}" >"$KUBECONFIG"
kubectl config use-context "kind-hm-w${_slot}" >/dev/null
cd "$_root" || return 1
unset _slot _root _state _src
