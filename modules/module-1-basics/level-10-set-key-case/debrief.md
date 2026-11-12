# The Silent --set

## What broke
The upgrade used `--set replicacount=4`, but the chart reads `.Values.replicaCount`. Helm stored the
unknown key in the release's values and rendered the chart without ever looking at it, so the Deployment kept
its default of one replica. The command reported success because, from Helm's point of view, it was.

## Why Helm behaves this way
Values are just a free-form, case-sensitive YAML tree merged from `values.yaml`, `-f` files and `--set`
flags. Helm does not know which keys a template will read, so it cannot warn about unknown ones - unless the
chart ships a `values.schema.json` with `additionalProperties: false` (the real defence, covered later in
the course). Template references to missing keys silently evaluate to empty.

## The fix
Run the upgrade with the correctly cased key. Do it without `--reuse-values`: when you pass new values,
`helm upgrade` starts from the chart defaults plus only the values given now, so the stray key disappears. With
`--reuse-values`, Helm merges your new `--set` on top of the previous release's user values and the stray
key survives forever.

## In real life
Typos in `--set` (case, a missing nesting level, `image.tag` vs `images.tag`) are among the most common
silent misconfigurations in CI. Habits that help: put overrides in reviewed values files instead of long
`--set` strings; after every deploy check `helm get values <rel>` and the live objects; and add a JSON schema
to charts you own.

## Commands worth remembering
- `helm get values <rel>` - what the user supplied; add `--all` for the merged result
- `helm template ./chart --set k=v | grep -n replicas` - verify the key does something before deploying
- `helm upgrade <rel> ./chart --set replicaCount=4`
- `kubectl get deploy <name> -o jsonpath='{.spec.replicas}'`

## Common mistakes
- `kubectl scale`: the next `helm upgrade` resets the replica count to the chart's value.
- `--reuse-values` with the corrected key: the typo stays in the release record.
- Assuming Helm validates keys - it does not.

## Helm 3 vs Helm 4
No difference. In both versions `helm upgrade` with new values but without `--reuse-values` or `--reset-then-reuse-values`
replaces the stored user values by the ones given now.
