# Empty Image

## What broke
The template referenced `.Values.image.respository` - a typo. No such key exists in `values.yaml`, so the
expression evaluated to nothing and the image string became `:1.27-alpine`. Kubernetes accepted the
Deployment (an image is just a non-empty string) but the kubelet refused to start the containers:
`InvalidImageName`.

## Why Helm behaves this way
`.Values` is a nested map. Looking up a key that is not there in a map is not an error in Go templates - it
yields the zero value, which prints as an empty string (or `<no value>` in some contexts). Only going one
level *deeper* into a missing parent (`.Values.imag.repository`) raises `nil pointer evaluating`.
So typos in the last path element fail silently, and the render, `helm lint`, the install and even
`helm status` all look healthy. Only the running workload shows the damage.

## The fix
Correct the path in the template and upgrade. The release then gets a new revision with the right Deployment.
Adding the misspelled key to values.yaml would "work" once, but overrides such as `--set image.repository=...`
would be ignored forever, because the template never reads that key.

## In real life
This is the classic "green deploy, red pods" bug. It survives code review because the diff looks reasonable.
Teams defend against it with a `values.schema.json` that forbids unknown keys, with `required` on mandatory
values (`{{ required "image.repository is required" .Values.image.repository }}`), and with a post-deploy
smoke test (`helm upgrade --wait`, `helm test`).

## Commands worth remembering
- `helm template ./chart | grep image:` - see the final image strings
- `helm get manifest <rel>` - what the release actually applied
- `kubectl describe pod <pod>` - the kubelet's view (Events, container state reasons)
- `helm upgrade <rel> ./chart --wait` - make the rollout part of the command

## Common mistakes
- `kubectl set image` or `kubectl edit`: the pods recover, but the next `helm upgrade` brings the typo back.
- Fixing values.yaml when the data was right and the template path was wrong.
- Reading `deployed` as "working": Helm only reports that the manifests were applied.

## Helm 3 vs Helm 4
No difference in templating. `helm status -o json` no longer carries the chart in Helm 4, use `helm history`.
