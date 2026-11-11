# The Mystery Override

## What broke
The chart and its defaults were fine. The *release* was installed with
`--set config.apiUrl=http://localhost:9999`, an override meant for local testing. Helm stored it as the
release's user-supplied values, so every render used it and the widget called a URL that only exists on a
developer's laptop.

## Why Helm behaves this way
A release is `chart + values`. Values come in layers: the chart's `values.yaml`, then `-f` files, then
`--set`. Helm saves the user layers in the release record so that upgrades and rollbacks are reproducible.
Because the override lives in the cluster and not in git, reading the chart tells you nothing about it:
the only way to see it is to ask the release.

## The fix
`helm get values <rel>` reveals the override. Redeploy with `helm upgrade <rel> ./chart --reset-values` so
the stored user values are discarded and the chart defaults apply (`helm uninstall` + `helm install` also
works, at the cost of history). The trap: a plain `helm upgrade <rel> ./chart` with no `--set`/`-f` at
all does NOT reset anything - when no new values are supplied, Helm reuses the previous release's user
values, override included. Passing any new values (`-f file`, `--set`) replaces the stored set instead, and
`--reuse-values` explicitly merges the old set on top.

## In real life
"It works in git but not in prod" is very often an override somebody typed once. Forensics order: `helm get
values` (what was supplied), `helm get values --all` (computed result), `helm get manifest` (what was
applied), `helm history` (when it changed). Teams that keep every environment's values in files and deploy only
from CI make these surprises traceable.

## Commands worth remembering
- `helm get values <rel> [--all] [--revision N]` - supplied or computed values, current or past
- `helm get manifest <rel>` - the rendered YAML
- `helm history <rel>` - revisions and their descriptions
- `helm upgrade <rel> ./chart --reset-values` - drop stored user values, use chart defaults
- `helm upgrade <rel> ./chart --reset-then-reuse-values` - new chart defaults + old user values

## Common mistakes
- Fixing the live ConfigMap with kubectl: the release record keeps the override and the next upgrade
  restores it.
- A plain `helm upgrade` (or `--reuse-values`): both keep the stored override.
- Editing the chart default to "match" the override - the chart was right.

## Helm 3 vs Helm 4
Same semantics in both: no new values means the old user values are reused. Both also offer
`--reset-then-reuse-values` (merge the chart's new defaults with the previous user values).
