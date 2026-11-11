# Wrong Ingress API - Walkthrough

1. `helm install portal ./docs-portal -n helmissions` fails with `no matches for kind "Ingress" in version "networking.k8s.io/v1beta1"`;
   v1beta1 Ingress was removed in Kubernetes 1.22.
2. See what the chart picks: `helm template portal ./docs-portal --dry-run=server | grep -B1 'kind: Ingress'` prints
   `networking.k8s.io/v1beta1`. (Without `--dry-run=server` (Helm 3: `--validate`) the render uses Helm's built-in default capability list, not the cluster's.)
3. `templates/_helpers.tpl` uses `.Capabilities.APIVersions.Has "networking.k8s.io/v1/ingress"`. `Has` compares
   exact strings, and the kind is `Ingress` with a capital I. Check `kubectl api-resources --api-group=networking.k8s.io -o wide`.
4. Fix the string to `networking.k8s.io/v1/Ingress`.
5. Verify with `helm template portal ./docs-portal --dry-run=server | grep -B1 'kind: Ingress'` (now v1), then
   `helm install portal ./docs-portal -n helmissions --wait` and `kubectl get ingress -n helmissions`.
