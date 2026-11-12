# Two Teams, One ClusterRole

## What broke
The `collector` chart was written for one tenant. Three of its objects are cluster-scoped, so they live in a single global name space no matter which
namespace the release is in, and the chart gave them fixed names (`helmissions-pod-reader` for the ClusterRole and ClusterRoleBinding, a fixed
PriorityClass). Team A's release owned them. Team B's install tried to create objects with the same names, and Helm refused:
they carry annotations naming team A's release and namespace. Fixing one name only moved the failure to the next object, and the ClusterRoleBinding also
hard-coded team A's namespace as the ServiceAccount's home, so even a successful install would have left team B without permissions.

## Why Helm behaves this way
Helm records ownership on every object it creates (`meta.helm.sh/release-name`, `meta.helm.sh/release-namespace` and `app.kubernetes.io/managed-by`).
It refuses to adopt an object that belongs to another release, because two releases managing one object would overwrite each other and the first
`helm uninstall` would delete it for both. Namespaces do not help: they scope names of namespaced objects only. Helm checks and reports conflicts one
object at a time, which is why you meet them in sequence.

## The fix
Make every cluster-scoped name a function of release name and namespace, reference those names consistently (roleRef, priorityClassName), derive the
ServiceAccount's namespace from `.Release.Namespace`, and run the pipeline: team A's objects are replaced by scoped ones, team B installs cleanly.

## In real life
Operators, monitoring agents, CRDs, webhooks and cluster roles are the usual suspects when a chart is installed twice on one cluster (per team, per environment
in a shared dev cluster, or for blue/green). Treat any cluster-scoped kind in a chart as a multi-tenancy decision: scope the name, make it optional, or
document that the chart is a singleton. `helm template | grep -E '^kind: (Cluster|Priority|Custom|Mutating|Validating)'` in CI catches them.

## Commands worth remembering
- `kubectl get clusterrole NAME -o yaml | grep -A3 annotations`
- `helm template REL ./chart -n NS | grep -B1 -A4 '^kind: Cluster'`
- `kubectl auth can-i list pods -A --as=system:serviceaccount:NS:SA`
- `helm install ... --take-ownership` (Helm 4) exists for deliberate adoption, which is not what is wanted here

## Common mistakes
- Re-annotating the objects (or adopting them) so the install goes through: the two releases then manage and delete each other's access.
- Renaming only the ClusterRole: the next conflict is one object further, and the binding's subject still points at team A.
- Forgetting that team A's own release still has the old shared names until it is upgraded.

## Postmortem
Root causes: cluster-scoped objects with fixed names in a chart used by multiple tenants; a hard-coded subject namespace. Contributing factors:
the chart had only ever been installed once; a second install is a different test than a first install.
Prevention: a CI job that installs the chart twice (different names/namespaces) into a throwaway cluster, lint rules for fixed names of cluster-scoped kinds,
and a team-onboarding checklist that includes "second tenant" testing.

## Helm 3 vs Helm 4
Ownership annotations and the conflict error are identical. Helm 4 adds `--take-ownership` to adopt objects deliberately; here it would only hide the real defect.
