# Storefront Without Its Cache

## What broke
`storefront/Chart.yaml` declared a dependency on `session-cache` (`repository: file://../session-cache`), but the
parent chart's `charts/` directory did not exist. `helm install` loads the chart from disk and checks that every
dependency named in `Chart.yaml` is physically present under `charts/`; if one is missing it stops with
`found in Chart.yaml, but missing in charts/ directory`. Nothing was sent to the cluster.

## Why Helm behaves this way
`Chart.yaml` only *declares* dependencies (name, version constraint, where to get them). At install time Helm does
not go and fetch anything: a chart must be self-contained, because a release stores the full chart, subcharts
included, in its release record. `helm dependency update` resolves the declarations, downloads or packages each
dependency into `charts/<name>-<version>.tgz` and writes `Chart.lock` (the exact versions chosen plus a digest of the
declarations). `helm dependency build` does the same but rebuilds `charts/` strictly from `Chart.lock`.
A `file://` repository is resolved relative to the parent chart directory and the subchart is packaged on the fly.

## The fix
Run `helm dependency update ./storefront` (or `build`), confirm `helm dependency list` reports `ok`, then install.
Commit `Chart.lock`; most teams git-ignore `charts/*.tgz` and let CI rebuild them.

## In real life
This is the classic "works on my laptop, fails in CI": a developer ran `helm dependency update` locally, `charts/` is
in `.gitignore`, and the pipeline runs `helm install` or `helm package` without a dependency step. Add
`helm dependency build` as the first step of every pipeline that touches an umbrella or application chart.
`helm lint` warns about the same condition (`chart directory is missing these dependencies`).

## Commands worth remembering
- `helm dependency list ./chart` — declared dependencies and whether they are present (`ok`, `missing`, `unpacked`)
- `helm dependency update ./chart` — resolve constraints, refresh `charts/` and `Chart.lock`
- `helm dependency build ./chart` — rebuild `charts/` exactly from `Chart.lock`
- `helm show chart ./chart` — print the parsed metadata including the dependencies

## Common mistakes
- Deleting the `dependencies:` block to get the install through: the release no longer contains the cache.
- Expecting Helm to read `../session-cache` at install time; `file://` is only consulted by `dependency update`.
- Forgetting to re-run the dependency command after changing the subchart: the old tarball in `charts/` is deployed.

## Helm 3 vs Helm 4
Identical here. Both print the same error text and both accept an unpacked directory in `charts/` as well as a `.tgz`.
