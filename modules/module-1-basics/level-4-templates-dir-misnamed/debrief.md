# The Empty Release

## What broke
The chart kept its manifests in a folder called `template/`. Helm only looks in `templates/`, so it
found nothing to render, created a release with an empty manifest, and reported success. No error, no
resources - the worst kind of failure to notice.

## Why Helm behaves this way
A chart is a directory convention: `Chart.yaml`, `values.yaml`, `templates/`, optional `charts/`, `crds/`.
Helm does not complain about unknown directories - charts may legitimately carry docs or extra files - and
a chart with zero templates is valid (library-like or metadata-only charts exist). So "no templates" is
not an error, just an empty release. Release history, revisions and `helm list` all work normally on an
empty release, which is exactly what makes it confusing.

## The fix
Rename the directory to `templates/` and `helm upgrade` the existing release. The upgrade creates
revision 2 with the real objects. Use `helm get manifest` as the first diagnostic whenever a "deployed"
release shows no workload.

## In real life
Typos in directory or file names (`template/`, `Templates/` on case-sensitive Linux but not on a Mac,
`.yml` files that were never added to git) produce empty or partial releases. CI should run
`helm template` and assert that expected kinds appear, or at least `helm lint`, before deploying.

## Commands worth remembering
- `helm get manifest <rel>` - what Helm applied (empty means nothing was rendered)
- `helm template <rel> ./chart | grep ^kind` - preview without a cluster
- `helm lint ./chart` - flags a chart without a templates directory
- `helm show chart ./chart` - metadata Helm parsed

## Common mistakes
- Running `helm template | kubectl apply` to get the objects: they exist but Helm does not own them.
- Uninstalling and reinstalling when a plain `helm upgrade` would keep history.
- Trusting `STATUS: deployed` without looking at the resources.

## Helm 3 vs Helm 4
Both treat a chart without templates as valid and install it as an empty release. Helm 4 behaves the
same here; only the lint wording may differ between versions.
