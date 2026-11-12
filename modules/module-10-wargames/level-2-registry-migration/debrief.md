# Registry Moved

## What broke
A registry migration is a cross-cutting change, and three different places carried the old assumption. The shared
`values/global.yaml` still named the retired registry, so every pod failed to pull. Once that was corrected, the
`indexer` subchart (vendored under `charts/`) still pulled from the old host because its template builds the image
from its own `image.repository` and never reads `global.imageRegistry`. Finally the `media` release asked for a tag
(`v1.0`) that the copy job had renamed to `1.0`, so it still failed - with a different error - after the registry
was fixed.

## Why Helm behaves this way
`global` values are only a convention: Helm passes `.Values.global` to every subchart, but a template has to use it.
A subchart author who hard-codes a repository silently opts out. Values are layered (chart defaults, then `-f` files in
order, then `--set`), so the last value wins and a default buried in a subchart is easy to miss. Helm renders whatever it
is told: it never verifies that an image reference exists. That is the kubelet's job, which is why each failure shows up
only as an `ErrImagePull` event, in the order the layers are peeled away.

## The fix
Point `global.imageRegistry` at the new registry, teach the subchart to honour it (or override its repository from the
parent values), correct the renamed tag, and redeploy through the same pipeline script so the files and the releases
agree. Verify each image with `helm get manifest`, not only the parent charts.

## In real life
Image-registry moves, mirror changes and "internal proxy" rollouts always reveal charts with hard-coded repositories,
init containers, hooks and test pods that pull images too. Grep the rendered output of every release for the old host name
(`helm template ... | grep image:`) before a cut-over, and keep the old registry readable until the last pod has moved.

## Commands worth remembering
- `kubectl describe pod POD | grep -A5 Events` and `kubectl get events --sort-by=.lastTimestamp`
- `helm get manifest REL | grep -n 'image:'`
- `helm template ./chart -f values/global.yaml -f values/REL.yaml | grep image:`
- `curl -s http://localhost:5001/v2/<repo>/tags/list` to see what a registry really holds
- `helm get values REL --all`

## Common mistakes
- Patching `kubectl set image` on the live Deployments: the next pipeline run restores the old registry.
- Fixing only the parent charts and forgetting that subcharts, hooks and tests have their own images.
- Using `--set` flags in a one-off command instead of the values files the pipeline reads.

## Postmortem
Root causes: registry host and path duplicated across values files and a subchart, an image tag renamed by the copy job
without updating consumers. Contributing factors: no rendered-manifest check for the old host; the cut-over time was a
hard deadline with no staged rollout.
Prevention: centralise the registry in one value, lint rendered output in CI for forbidden registries, copy tags verbatim,
and keep old and new registries both available for a deprecation window.

## Helm 3 vs Helm 4
No difference for this level. With Helm 4's default server-side apply a live `kubectl set image` patch also raises a
field-manager conflict on the next upgrade instead of being reverted silently; either way the workspace must be fixed.
