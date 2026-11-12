# --reuse-values Ate My Default

## What broke
Chart 2.0.0 introduced `metrics.port` with a default in its `values.yaml`. The CI job upgraded with `--reuse-values`, which
tells Helm to start from the *previous release's* computed values instead of the new chart's defaults. The old release
had no `metrics` key, so the new template evaluated `.Values.metrics.port` against nil: `nil pointer evaluating interface {}.port`.

## Why Helm behaves this way
A normal `helm upgrade` computes values as: chart `values.yaml` defaults + the values given on this command line (the
user-supplied values of earlier revisions are forgotten). `--reuse-values` replaces the *base* by the old release's
fully computed values (old chart defaults + old user values); the new chart's defaults then only fill keys that do not exist
anywhere, and in practice any new top-level key is simply missing. `--reset-then-reuse-values` (Helm 3.14+, also in Helm 4)
is the sane compromise: reset to the new chart's defaults, then apply the old release's *user-supplied* values, then this
command's `--set` flags.

## The fix
`helm upgrade notifier ./notifier -n helmissions --reset-then-reuse-values`. The upgrade keeps `replicaCount: 2` and
picks up `metrics.port: 9102`. The most robust pattern is to keep every override in a values file under version control
and run `helm upgrade -f values.yaml` so no state lives only in the cluster.

## In real life
`--reuse-values` is attractive in CI because nobody wants to re-list 30 `--set` flags, and it works fine until a chart upgrade
adds a value, renames a key, or changes a default - at which point deployments start failing, or worse, silently run with
stale defaults. Chart bumps via Renovate/Dependabot hit this regularly. Prefer GitOps-style values files, and use
`helm get values <rel>` to export the current overrides before a risky upgrade.

## Commands worth remembering
- `helm get values <rel>` vs `helm get values <rel> --all` - user-supplied vs computed values
- `helm upgrade --reset-then-reuse-values` - new defaults, old overrides
- `helm show values ./chart` / `helm diff upgrade` (plugin) - see what changes before applying

## Common mistakes
- Dropping `--reuse-values` while the job still passes other `--set` flags: the upgrade "works" but silently resets replicas, resources, hosts.
- Using `--reset-values` thinking it keeps your overrides - it discards them.
- Assuming `--reuse-values` merges new chart defaults.

## Helm 3 vs Helm 4
`--reuse-values` behaves the same in both. `--reset-then-reuse-values` was added in Helm 3.14, so it is available on every
version this game supports. Observed on Helm 4.3: a `helm upgrade` that supplies no values at all (no `-f`, no `--set`) quietly keeps the previous user-supplied values, but the moment any `--set`/`-f` is present, every other earlier override is dropped. That is why CI jobs that add a single `--set image.tag=...` lose the rest of the configuration.
