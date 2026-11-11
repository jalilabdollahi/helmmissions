# Same Chart Twice

## What broke
`inventory/Chart.yaml` listed the `kvstore` dependency twice with identical `name`. Helm requires every dependency to be
unique by `name` or, when set, by `alias`, and it validates that before loading a single template, so even
`helm dependency update` and `helm template` fail with `more than one dependency with name or alias "kvstore"`.

## Why Helm behaves this way
A subchart's identity in the parent is its name or alias. That identity does three jobs. It is the key under which the
parent's `values.yaml` scopes values to that subchart (`primary.mode` reaches only the instance aliased `primary`).
It is the `.Chart.Name` the subchart's templates see, so a chart that builds object names from
`{{ .Release.Name }}-{{ .Chart.Name }}` automatically produces distinct objects for each alias
(`inventory-primary`, `inventory-replica`). And it is what `condition:` and `import-values` talk about.
One tarball in `charts/` serves both entries; Helm instantiates it once per alias.

## The fix
Add `alias: primary` and `alias: replica`, matching the value blocks the team already wrote. After
`helm dependency update` the release contains two Deployments from the same subchart, each configured separately.

## In real life
Aliasing is how you run two databases, two ingress classes or a blue and a green copy of a component from a single
chart without copy-pasting it. The trap is a subchart whose templates use hard-coded names (`name: cache`): both
instances then render the same object and the second one overwrites or collides with the first. Subcharts meant to be
aliased must derive names from `.Release.Name` and `.Chart.Name` (or a helper that does), which is also the signal to
check when a duplicate-resource error appears after adding an alias.

## Commands worth remembering
- `helm dependency list ./chart` — shows name and alias of each dependency
- `helm template r ./chart | grep -E '^# Source'` — which subchart instance produced which file
- `helm get values <rel> --all` — computed values, nested under each alias
- `helm show values ./chart/charts/<sub>.tgz` — the defaults an alias block overrides

## Common mistakes
- Deleting the second entry: the release then has no replica at all.
- Choosing aliases that do not match the keys in `values.yaml`: the settings never reach the instances and the objects get unexpected names.
- Copy-pasting the subchart into a second chart just to get a second instance.

## Helm 3 vs Helm 4
Same validation message and the same alias semantics in both versions.
