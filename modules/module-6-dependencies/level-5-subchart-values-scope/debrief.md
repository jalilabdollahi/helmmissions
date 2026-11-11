# Values Not Reaching The Subchart

## What broke
The photo desk's settings sat under a `resizer:` key in the parent's `values.yaml`, but the dependency is called
`image-resizer`. Helm never reported a problem: to Helm, `resizer:` is just another parent value nobody reads, and
the subchart kept running on its own defaults (1 replica, 1024 px).

## Why Helm behaves this way
Values flow down one way. For every subchart Helm takes the top-level key of the parent's values that equals the
subchart's name (or alias) and merges it over the subchart's own `values.yaml`; everything else in the parent's values
is invisible to the child. There is no schema check, so a misnamed key is not an error, only a no-op. The precedence
chain is: subchart defaults, then the parent's `values.yaml` entry for that subchart, then `-f` files, then `--set`
(all of which use the same `<name>.<key>` addressing). Hyphens in names are fine; `--set image-resizer.replicaCount=3`
works as written.

## The fix
Use the exact dependency name (or alias) as the key, then upgrade. `helm get values <release> --all` shows the
final, merged result under each subchart's key, which is the quickest way to confirm that values arrived.

## In real life
This is the classic "I changed values.yaml and nothing happened" ticket. Typos, a renamed dependency or a newly introduced alias
all silently orphan values. A JSON schema (`values.schema.json`) in the *subchart* cannot catch it because the stray key
lives in the parent; a schema with `additionalProperties: false` in the parent can. Also remember that `kubectl scale`
or `kubectl set env` hotfixes are reverted by the next upgrade because the release still holds the old values.

## Commands worth remembering
- `helm get values <rel> --all` — merged values per subchart
- `helm template <rel> ./chart --debug` — rendered result plus computed values
- `helm show values ./chart/charts/<sub>.tgz` — what keys the subchart really offers
- `--set <subchart>.<key>=value` — same addressing as in values.yaml

## Common mistakes
- Setting `--set replicaCount=3` at the top level: it reaches the parent's own Deployment, not the subchart.
- Nesting under the chart's directory or repository name instead of the dependency `name`/`alias`.
- Fixing the live Deployment with `kubectl` and thinking the release is fixed.

## Helm 3 vs Helm 4
No difference. Both silently ignore keys that no chart consumes.
