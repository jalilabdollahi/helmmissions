# Wrong Namespace DNS

## What broke
Splitting one namespace into two broke the front end's idea of where the back end lives, and the failure had three
layers. The front end addressed the back end by its short Service name, which only resolves within the same namespace. Its
pod spec had also inherited `dnsPolicy: Default` from an old chart, so the pod ignored the cluster DNS entirely and could not
resolve any `*.svc.cluster.local` name. And the back end's Service forwarded to port 8081 while the container listens on 8080,
so even a resolved name ended in "connection refused". Each fix only revealed the next error.

## Why Helm behaves this way
Helm does not know about DNS or namespaces at runtime; it applies objects into one namespace per release. Kubernetes DNS
gives every Service the name `<svc>.<ns>.svc.cluster.local`, and a pod's `/etc/resolv.conf` adds only its *own*
namespace to the search path (with the default `ClusterFirst` policy). `dnsPolicy: Default` means "inherit the node's
resolver", which is correct for a few infrastructure pods and wrong for everything else. A Service with no matching
endpoint port gives a refused connection, not a DNS error.

## The fix
Use the fully qualified service name (or `service.namespace`) in the front end's values, restore `dnsPolicy: ClusterFirst`,
and correct the Service's `targetPort`; then redeploy both releases from the workspace.

## In real life
Namespace splits (tenancy, per-team clusters, environment separation) always cause this: short names that worked in a
shared namespace silently stop working. Make cross-namespace addresses explicit configuration (a value, not a hard-coded
string), test with `nslookup` and `wget` from inside the pod, and treat DNS errors, refused connections and HTTP errors as
three distinct layers.

## Commands worth remembering
- `kubectl exec POD -- cat /etc/resolv.conf`, `kubectl exec POD -- nslookup NAME`
- `kubectl get svc,endpointslices -n NS`, `kubectl describe svc NAME`
- `kubectl get deploy NAME -o jsonpath='{.spec.template.spec.dnsPolicy}'`
- `helm get manifest REL | grep -E 'dnsPolicy|targetPort'`

## Common mistakes
- Creating a second copy of the back end in the front end's namespace: the page works, but it is not the real back end.
- Editing the live Deployment or Service: the next deploy reverts it.
- Fixing the host name and stopping when the error message merely changes.

## Postmortem
Root causes: short name relied on a shared namespace; a stale `dnsPolicy: Default` in values; a wrong `targetPort`.
Contributing factors: no smoke test of the cross-namespace path after the tenancy change; both releases reported
`deployed` and every pod was Ready, so nothing alerted.
Prevention: a synthetic check that exercises the whole request path, a lint rule against `dnsPolicy: Default` for
application pods, and explicit `service.namespace` values for cross-team dependencies.

## Helm 3 vs Helm 4
No difference. (With Helm 4's server-side apply, a hotfix applied with `kubectl patch` can also surface as a
field-manager conflict on the next `helm upgrade`, which is another reason to fix the values.)
