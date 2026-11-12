# Nowhere To Land

## What broke
`helm install -n helmissions-staging` targeted a namespace that did not exist. Helm needs the
namespace for two things: the Secret that stores the release record, and the namespaced objects in the
chart. The Kubernetes API answered `namespaces "helmissions-staging" not found` and the install aborted.

## Why Helm behaves this way
By default Helm treats the namespace as something that belongs to the cluster operator: it will not
silently create namespaces, because namespaces carry policy (quotas, network policies, pod security
labels, RBAC). Creating one implicitly could land workloads in an unprotected namespace after a typo.
`--create-namespace` is the explicit opt-in - and it creates a bare namespace, with no labels or quotas.

## The fix
Add `--create-namespace` to the install (or create the namespace first with `kubectl`/GitOps and install into
it). Keep the namespace the ticket asks for; installing into `helmissions` would "work" and put the
service in the wrong place.

## In real life
Typos in `-n` are the most common cause: with `--create-namespace` in a pipeline, a misspelt namespace is
created quietly and the release lands there. Many teams therefore create namespaces through Terraform or
GitOps (with labels and quotas) and keep `--create-namespace` for dev and demo clusters. Remember that
`helm uninstall` does not delete a namespace that Helm created.

## Commands worth remembering
- `kubectl get namespaces` - what exists
- `helm install ... -n <ns> --create-namespace`
- `helm list -A` / `helm list -n <ns>` - which namespace holds a release

## Common mistakes
- Installing into another existing namespace "just to make it work".
- Forgetting `-n` on later commands: `helm list` shows only the current namespace by default.
- Expecting `helm uninstall` to remove a namespace it created.

## Helm 3 vs Helm 4
Same behaviour and error. `--create-namespace` exists in both (Helm 3.2+).
