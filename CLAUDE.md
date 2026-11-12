# HelmMissions — notes for Claude

- Levels are hand-authored; contract in docs/LEVEL_SPEC.md, curriculum in docs/CURRICULUM.md.
  The reference level is modules/module-1-basics/level-1-chart-version-missing.
- Test levels end-to-end with scripts/test_levels.py. Never use the user's global kube context:
  either `source scripts/agent_env.sh <slot>` (own kind cluster hm-w<slot>) or
  `export KUBECONFIG=$PWD/.hm-shared/main/kubeconfig` (cluster kind-helmissions).
- Primary target is Helm 4 (installed v4.3); keep Helm 3.14+ compatibility where possible.
