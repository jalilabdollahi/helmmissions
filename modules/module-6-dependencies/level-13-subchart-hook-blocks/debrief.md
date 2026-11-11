# A Subchart's Hook Blocks Everything

## What broke
The `schema-migrator` subchart ships a `pre-install,pre-upgrade` hook Job that refuses to run without a database host.
The parent's `database.host` feeds the API, but the subchart reads its own `.Values.database.host`, which defaults to an
empty string, so the Job exited 1. Because Helm waits for pre-install hooks, one failed hook stopped the whole release:
no Deployment from the parent was ever created, and the release was recorded as `failed`.

## Why Helm behaves this way
Hooks are ordinary templates with `helm.sh/hook` annotations, and subchart hooks are part of the parent release.
Helm creates hook resources in phases (`pre-install` before anything else), waits for Jobs to complete, and treats a failed
hook as a failed phase. That is deliberate: a migration that did not finish must not be followed by an application that expects the new schema.
Values are scoped per chart: the subchart gets its defaults overlaid with the parent's block named after it (`schema-migrator:`),
and nothing else, so the parent's own `database.host` is invisible to it. Unless you declare a `global`, every setting a subchart needs must
be passed explicitly.

## The fix
Pass the host to the subchart (`schema-migrator.database.host`), then upgrade or reinstall so the hook re-runs. The hook's
`before-hook-creation` delete policy removes the old failed Job before creating the new one, and the successful Job remains for inspection.
`--no-hooks` would let the release go green without ever applying the schema, which is the most dangerous "fix".

## In real life
Pre-install and pre-upgrade hooks from vendored subcharts (database migrations, CRD installers, secret bootstrap) are a frequent reason
for "the pods were never even created". Always look at `kubectl get job,pod` and `kubectl logs job/...` for the hook, not at the
application pods. Make subcharts fail loudly with a clear message when a required value is missing (as this one does), and keep hook Jobs
with `backoffLimit` and `activeDeadlineSeconds` set so a mistake fails in seconds instead of hanging a pipeline.

## Commands worth remembering
- `kubectl logs job/<release>-<hook>` — why the hook failed
- `helm get hooks <release>` — the rendered hook manifests of the current revision
- `helm template <rel> ./chart --show-only charts/<sub>/templates/<file>.yaml` — render one subchart template
- `helm upgrade <rel> ./chart --wait` — re-run pre-upgrade hooks and the release

## Common mistakes
- Using `--no-hooks` to get past it: the migration never runs.
- Setting the value at the parent's top level (it only reaches the parent's own templates).
- Deleting the hook Job by hand and retrying without changing the cause.

## Helm 3 vs Helm 4
Same hook semantics. Helm 4 words the error as `failed pre-install: resource Job/<ns>/<name> not ready. status: Failed...`; Helm 3 phrases the same failure differently
(it mentions the Job and its failure reason). Helm 4 also allows `helm upgrade` on a
release whose first install failed; older Helm releases can refuse with `has no deployed releases`, in which case `helm uninstall` first and install again.
