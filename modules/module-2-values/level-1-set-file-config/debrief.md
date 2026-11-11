# A Path Is Not A File

## What broke
The release was installed with `--set siteConfig=./site.conf`. Helm stored the 11-character string
`./site.conf` as the value, rendered it into the ConfigMap, and nginx tried to parse that text as its
configuration. The release was `deployed` (Helm applied exactly what it was asked to) while the pod
crash-looped: Helm's status says the manifests were applied, not that the application works.

## Why Helm behaves this way
`--set` is a tiny expression language for scalars: everything right of `=` is a value, never a path.
Helm has two file-aware mechanisms on purpose:
- `--set-file key=path` reads the file at the path and stores its full contents as the value
  (multi-line, quotes and all, no escaping needed).
- `-f/--values file.yaml` merges a YAML document, where a literal block (`siteConfig: |`) carries the text.
Because both end up as ordinary values, `helm get values` shows the whole config afterwards and the next
upgrade can reuse it.

## The fix
`helm upgrade landing ./landing -n helmissions --set-file siteConfig=./site.conf`
The chart already checksums the ConfigMap into a pod annotation, so the upgrade rolls the pods.

## In real life
Config files owned by another team (nginx, prometheus rules, JVM options) are often injected at deploy
time in CI. A pipeline that does `--set cfg=$FILE_PATH` "works" in review because the release turns green.
Always look at the rendered ConfigMap (`helm get manifest`) or run `helm template` in CI and assert on it.
Large files are better kept in the chart under `files/` and read with `.Files.Get`, so config and chart
version travel together.

## Commands worth remembering
- `helm get values <rel>` / `helm get manifest <rel>` - what Helm really stored and applied
- `helm upgrade --set-file key=path` - inject file contents
- `helm template ./chart --set-file key=path | less` - preview before touching the cluster

## Common mistakes
- Patching the ConfigMap with `kubectl edit`: the next `helm upgrade` silently reverts it.
- Using `$(cat site.conf)` inside `--set`: commas, braces and newlines in the file break the parsing.
- Trusting `STATUS: deployed` as proof that the app is healthy.

## Helm 3 vs Helm 4
`--set`, `--set-file` and `-f` behave the same in Helm 3 and Helm 4. Helm 4 uses server-side apply for
new installs, but the ConfigMap/Deployment update flow described here is identical.
