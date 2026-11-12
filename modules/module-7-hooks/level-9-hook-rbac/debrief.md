# Forbidden Inside The Hook

## What broke
`tenant-onboarding` has a pre-install Job that lists ConfigMaps to make sure no maintenance window is active. The Job pod ran as the
namespace's `default` ServiceAccount, which Kubernetes RBAC gives no permissions, so the API answered `403 Forbidden` and the Job exited
non-zero. Helm treats a failed pre-install hook as a failed install, so nothing else, including the Deployment, was created.

## Why Helm behaves this way
Hooks are ordinary Kubernetes objects with ordinary identities. A Job that talks to the API needs a ServiceAccount, a Role and a
RoleBinding **that already exist when its pod starts**. Helm creates regular templates only after the `pre-install` hooks have finished, so RBAC
declared as normal resources arrives too late. The classic solution is to ship the ServiceAccount, Role and RoleBinding as hooks of the same
phase, with a lower `hook-weight` than the Job (weights are ascending, negative values are fine), and `before-hook-creation` as delete policy so upgrades can
recreate them. Helm waits for each hook, in weight order, before starting the next.

## The fix
Create `<release>-preflight` ServiceAccount, Role (`list` on `configmaps`) and RoleBinding as `pre-install,pre-upgrade` hooks with weight
`-10`, and set `serviceAccountName` on the Job. Granting only the verbs the hook uses is the point: do not bind `cluster-admin` to make errors
disappear. A hook ServiceAccount is not removed by uninstall unless its delete policy says so; decide whether that is what you want.

## In real life
Pre-install checks, DB bootstrap Jobs and cleanup Jobs often need API access (listing secrets, patching ConfigMaps, creating namespaces). These
failures only show up on the first install in a new cluster or namespace, because the hand-made RoleBinding that made it work in the
test environment is not in the chart. Always test hooks in an empty namespace.

## Commands worth remembering
- `kubectl logs job/<hook-job>` — the API's `forbidden` message names the user, verb and resource
- `kubectl auth can-i list configmaps --as system:serviceaccount:<ns>:<sa> -n <ns>` — test permissions quickly
- `helm get hooks <rel>` — check phases and weights of the RBAC objects and the Job

## Common mistakes
- Declaring the Role and RoleBinding as normal templates: they exist only after the hook has already failed.
- Creating the RoleBinding with `kubectl`: green here, red in every fresh environment.
- Giving the hook far more permissions than it needs.

## Helm 3 vs Helm 4
No difference in behaviour: weights decide the order in both and each hook is waited for before the next starts. Helm 4's error text for the failing
hook is `failed pre-install: resource Job/<ns>/<name> not ready. status: Failed`.
