hm-audit — list containers without resource limits in a release.

  helm plugin install ./hm-audit
  helm hm-audit RELEASE -n NAMESPACE

plugin.yaml                  plugin definition (Helm 4, apiVersion v1, type cli/v1)
scripts/audit.sh             the command
scripts/install-rules.sh     install hook: creates rules.env from rules.default
rules.default                audit rules (copied to rules.env at install time)
