# Kustomize Inflates Helm

## What broke
The `helmCharts` entry in `platform/kustomization.yaml` pointed at a `chartHome` folder and a `valuesFile` that do not
exist. Kustomize first could not find the chart ("no chart found at ''" — it fell back to trying to pull it from a repo
that was never given) and, once that was fixed, could not read the values file. Nothing was rendered, so nothing could be applied.

## Why Helm behaves this way
`kubectl kustomize --enable-helm` runs the `helm` binary on your machine as a *generator*: for each `helmCharts` entry it runs
`helm template` with the release name, namespace, `valuesFile` and `includeCRDs` settings, then feeds the resulting
YAML into the normal kustomize pipeline (labels, patches, namePrefix...). Kustomize resolves the chart as
`<chartHome>/<name>` when no `repo` is given, and relative to the kustomization directory, not to the chart. Because
Helm is only the renderer, there is no release record, no hooks lifecycle, no `helm rollback` and no `helm list` —
`kubectl apply` owns the objects. Capabilities-based templates also see only what `helm template` sees (no cluster API list).
kustomize does not set the namespace of inflated objects for you here; the chart's own `.Release.Namespace` does.

## The fix
Point `chartHome` and `valuesFile` at the real locations (or move files to where the kustomization looks), verify the rendered
YAML, and apply it. Keep inflating from the vendored chart so upgrades stay a version bump, not a copy-paste.

## In real life
Teams that standardised on Kustomize overlays (Argo CD, Flux Kustomization, `kubectl apply -k`) use `helmCharts` to consume
third-party charts without adopting Helm releases, and then patch what the chart does not expose. The trade-offs: you lose
Helm's release history and `helm test`, `--enable-helm` must be passed everywhere (CI, Argo CD's `kustomize.buildOptions`),
the `helm` binary version on the builder affects the output, and chart upgrades are only as safe as your review of the
rendered diff. Commit rendered output or run `kubectl diff` in pull requests.

## Commands worth remembering
- `kubectl kustomize --enable-helm DIR` — render the overlay with Helm inflation
- `kubectl kustomize --enable-helm DIR | kubectl apply -f -` — apply it
- `kubectl diff -f -` — preview against the cluster
- `helm template NAME CHART -f VALUES` — render a chart without kustomize to compare

## Common mistakes
- Applying `helm template` output directly: you lose the kustomize layer (here the `env: prod` label).
- Forgetting `--enable-helm`: kustomize refuses `helmCharts` entries.
- Using `helm install` for a folder that is meant to be GitOps-rendered: two owners fight over the same objects.

## Helm 3 vs Helm 4
Kustomize just shells out to whichever `helm` is on the PATH, so the behaviour follows that binary. Both Helm 3.14+ and Helm 4 work
with kubectl's bundled kustomize 5.x; Helm 4's server-side-apply default is irrelevant because kustomize only calls
`helm template`.
