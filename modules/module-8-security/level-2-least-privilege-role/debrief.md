# 403 From The API

## What broke
The syncer was granted `get/list/watch` on pods, but its code also lists ConfigMaps. Kubernetes RBAC is
deny-by-default: the API server answered `403 Forbidden` for the one resource no rule mentioned, and the
readiness probe (which needs both calls to succeed) kept the pod out of the Service.

## Why Helm behaves this way
Helm did exactly what the chart said: it created a ServiceAccount, a Role and a RoleBinding. RBAC objects are
ordinary manifests, so a missing rule is a chart bug, not a Helm bug. Helm cannot know what the container will
call. The only way to find the gap is to read the application's log or ask the API:
`kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>`.

## The fix
Add a rule for the core-group resource `configmaps` with the smallest set of verbs that works, to the
Role that the chart already ships, and upgrade the release. Keep the Role namespaced and the binding bound to
that one ServiceAccount.

## In real life
The tempting shortcuts are `verbs: ["*"]`, `resources: ["*"]` or a ClusterRoleBinding to `cluster-admin`.
They make the 403 vanish in a minute and then sit in production for years: a compromised pod with a wildcard
Role can read every Secret in the namespace (including other apps' database passwords and its own ServiceAccount
token's reach), create workloads and pivot. Auditors and policy engines (Kyverno, OPA Gatekeeper, `kubectl-who-can`,
`rbac-lookup`) flag wildcard rules for exactly that reason. Fix RBAC in the chart so the rule survives the next
upgrade — a `kubectl edit role` patch is overwritten as soon as Helm reconciles.

## Commands worth remembering
- `kubectl auth can-i --list -n NS --as=system:serviceaccount:NS:SA` — everything the identity may do
- `kubectl auth can-i list secrets -n NS --as=...` — prove the negatives too
- `helm get manifest REL | grep -B2 -A12 'kind: Role'` — what the release actually shipped
- `kubectl describe role,rolebinding -n NS`

## Common mistakes
- Granting `*` on resources or verbs "just to see if it works" and forgetting to remove it.
- Using a ClusterRole/ClusterRoleBinding for something that only touches one namespace.
- Hot-patching the Role with `kubectl edit`: the next `helm upgrade` silently reverts it.
- Forgetting that `get`, `list` and `watch` are separate verbs; add only the ones the client uses.
