# Patch After Render

## What broke
The team needed a cross-cutting change (a label on every object plus a sidecar) in a chart they do not own. They
built a post-renderer that pipes Helm's output through `kubectl kustomize`, but the script saved the incoming
manifests as `all.yaml` while the kustomization listed `rendered.yaml`. `kubectl kustomize` failed, and Helm only
reports that the plugin "exited with error" — the useful message stays on the plugin's stderr.

## Why Helm behaves this way
After Helm renders the templates it can hand the complete manifest stream to a post-renderer: a program that reads YAML
on stdin and writes YAML on stdout. Whatever comes out is what Helm stores in the release record and sends to the
cluster, so `helm get manifest`, rollback and diff all see the patched version. That is the difference from
`kubectl label` after the fact: changes made outside Helm are invisible to the release and are overwritten by the
next upgrade (or fought over by server-side apply). Kustomize is a natural engine because patches, label
transformers and `includeTemplates` are declarative and survive chart upgrades; `includeSelectors: false` keeps the
immutable Deployment selector intact.

## The fix
Make the plugin's file names consistent, test it in isolation with `helm template ... --post-renderer NAME`, then run
the upgrade with `--post-renderer`. The vendored chart stays byte-for-byte upstream, so Renovate/Dependabot bumps still apply.

## In real life
Platform teams use post-renderers for organisation-wide policy that upstream charts do not expose: cost labels, extra
annotations for service meshes, injecting sidecars, rewriting image registries, adding tolerations. Argo CD and Flux
support them too (Flux `postRenderers: kustomize`, Argo CD via Kustomize+Helm or plugins). The costs are real: the
patched output depends on the post-renderer being present in every pipeline (it is not part of the chart), failures
are opaque, and each patch must be re-tested after chart upgrades. Prefer chart values or `.Values.global` hooks when
the chart offers them; use a post-renderer when it does not.

## Commands worth remembering
- `helm plugin install ./dir` / `helm plugin list` — install and list plugins (TYPE column shows `postrenderer/v1`)
- `helm template ... --post-renderer NAME` — test without touching the cluster
- `helm upgrade ... --post-renderer NAME --post-renderer-args ARG` — use it and pass arguments
- `helm get manifest REL` — shows the post-rendered result that is stored
- `kubectl kustomize DIR` — debug the kustomization directly

## Common mistakes
- Labelling live objects with `kubectl label`: the release does not contain it and the next upgrade removes it.
- Using `commonLabels` in the kustomization: it also rewrites selectors, which are immutable on existing Deployments.
- Forgetting `--post-renderer` on later upgrades (CI job vs. laptop): the patch silently disappears. Put it in the pipeline.

## Helm 3 vs Helm 4
Helm 3 post-renderers are plain executables (`--post-renderer ./render.sh`, with `--post-renderer-args`). Helm 4 turned them
into plugins: the flag takes a plugin *name*, the plugin has `apiVersion: v1`, `type: postrenderer/v1`,
`runtime: subprocess` and a `runtimeConfig.platformCommand`, and is installed with `helm plugin install` (local
directories install in "development mode" as a symlink). Helm 4 does not show the plugin's stderr; run it by hand to
debug.
