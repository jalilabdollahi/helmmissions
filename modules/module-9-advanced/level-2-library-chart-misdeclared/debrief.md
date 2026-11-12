# Not A Library After All

## What broke
`mqlib` was supposed to be a bag of shared named templates, but it was declared as an ordinary application
chart and its helper file was an ordinary template (`mq-config.yaml`) that also contained a fixed-name demo
ConfigMap. Helm renders an application subchart exactly like the parent, so every consumer release silently got
a ConfigMap named `mq-defaults`. The first release to install owned it; the second one hit Helm's ownership
check ("exists and cannot be imported into the current release").

## Why Helm behaves this way
Helm decides what a chart is from `type:` in Chart.yaml (`application`, the default, or `library`). A library
chart is never rendered into manifests and cannot be installed (`library charts are not installable`).
When a library is used as a dependency, Helm loads only its partials — files whose names start with `_` — so
a helper placed in `mq-config.yaml` is not loaded at all and `include` fails with `no template ... associated with
template "gotpl"`. An application chart has no such filter: all files render, and Helm stamps the objects with
`meta.helm.sh/release-name` annotations. That is why the second release refuses to adopt an object that the
first one owns.

## The fix
Declare `type: library`, move helper code into `_*.tpl` files, and delete anything that is not a `define`.
Because consumers carry a packaged copy of the library in `charts/`, run `helm dependency update` in each of them
before upgrading. Upgrade the release that owns the stray object first (the object is pruned from its manifest),
then install the other.

## In real life
This bites teams that start a shared chart as "just another chart" and later start depending on it. Symptoms
are always indirect: extra objects with fixed names, duplicate CRDs, `already exists` errors only on the second
environment, or helpers that exist locally but vanish in CI because the packaged copy was stale. Add
`helm template` plus `helm lint` of every consumer to the library's CI, and publish the library to an OCI
registry so consumers pin versions instead of using `file://` paths.

## Commands worth remembering
- `helm show chart ./lib` — check `type`
- `helm template ./consumer | grep '# Source'` — find which chart/file produced an object
- `helm get manifest REL | grep -c NAME` — see which release owns an object
- `helm dependency update` — refresh `charts/` after changing a local dependency

## Common mistakes
- Deleting the conflicting object with `kubectl delete` and retrying: the library still renders it, so the next
  upgrade collides again.
- Renaming the file but leaving the chart as `application`: it works today but `helm install ./lib` still deploys it.
- Forgetting to refresh `charts/` — the consumer keeps rendering the old packaged library.

## Helm 3 vs Helm 4
Same rules in both. Helm 4's server-side apply does not bypass the ownership check, so the error text is the
same; In both versions the ownership check runs before a release record is written, so nothing needs cleaning up before retrying.
