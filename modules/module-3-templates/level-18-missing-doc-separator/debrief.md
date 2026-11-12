# The Disappearing Deployment

## What broke
`templates/app.yaml` contained a Deployment and a Service back to back, without the YAML document separator `---`.
Helm splits a rendered file into manifests on `---` lines. Without one, the whole file is a single document in which the
keys `apiVersion`, `kind`, `metadata` and `spec` each appear twice. The parser Helm uses keeps the last value of a
repeated key, so what was applied was a Service built from the Service's keys; the Deployment's data was overwritten and
never reached the cluster.

## Why Helm behaves this way
Helm does no semantic checks on rendered YAML. It does not validate duplicate keys (strict YAML parsers would), it only
asks "is this parseable?" and then applies what comes out. The result is the worst kind of failure: a successful install,
a `deployed` status, and a missing workload. (When the second object has fields that do not exist on the merged kind,
you instead get a loud schema error from the API server such as `.spec: field not declared in schema`.)

## The fix
Separate documents with `---` on a line by itself, or give each object its own file. `helm template` followed by
`grep '^kind:'` is a quick sanity check that every object you expect is there. After fixing, `helm upgrade` creates the
missing Deployment as part of a new revision.

## In real life
Copy-pasting an object from `kubectl get -o yaml` or another chart into an existing file is the usual trigger. It also
happens when a separator sits inside a `{{- if }}` block that is skipped. Adding a CI step that counts the rendered kinds
(or runs `kubeconform`/`kubectl apply --dry-run=server` on `helm template` output) turns this silent failure into a loud one.

## Commands worth remembering
- `helm get manifest <rel>` - the exact manifest stored for the release
- `helm template <rel> ./chart | grep -E '^(kind|  name):'` - inventory of rendered objects
- `kubectl get all -n <ns>` - compare with the inventory

## Common mistakes
- Creating the Deployment with `kubectl create`: Helm doesn't own it, `helm uninstall` leaves it behind, and the chart is still wrong.
- Trusting `deployed`: it only means the apply did not error.
- Adding `---` at the top of the file only: that separates nothing between the two objects.

## Helm 3 vs Helm 4
The merge-on-duplicate-keys behaviour is the same on both; the object that survives is the last one. In Helm 4 you may see a
server-side apply `field not declared in schema` error instead when the merged object is invalid for the surviving kind.
