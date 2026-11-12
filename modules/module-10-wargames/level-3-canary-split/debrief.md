# The 50% Canary

## What broke
A "10% canary" with the same Service in front of two Deployments is only a replica ratio, and three details broke it.
The stable track had one replica instead of nine, so even a perfect canary would take 50% of the requests. The canary
pods were labelled `app.kubernetes.io/name: catalog-canary`, so the shared Service did not select them at all (0% of the
traffic, which is why the dashboard looked random). And the canary's readiness probe asked for `/health`, which the
container does not serve; the pod never became Ready and the canary release was left `failed`.

## Why Helm behaves this way
Kubernetes Services are label selectors over ready pods; they know nothing about releases, tracks or weights. A split by
replica count therefore depends on three things being true at once: the same selector label on both Deployments, readiness
that reflects reality, and the right pod counts. Helm only renders what the values say. A release whose `--wait` timed out is
stored as `failed` but its objects stay in the cluster, which is why one canary pod existed yet received no traffic.

## The fix
Raise the stable track to nine replicas, remove the canary's label override so its pods carry the shared selector label,
correct the readiness path, and run both releases again with the same script. A failed release can simply be upgraded
once its values render correctly.

## In real life
Replica-ratio canaries are common where there is no service mesh or ingress weighting, and they break silently: a
renamed label means a canary no one sees; a missing readiness check sends traffic to a dead pod. Always check
`kubectl get endpointslices` for the Service after a canary deploy, and sample real responses, not just pod counts.
Remember that scaling stable changes the canary percentage as well.

## Commands worth remembering
- `kubectl get pods --show-labels`, `kubectl get endpointslices -l kubernetes.io/service-name=SVC`
- `kubectl describe pod POD` (readiness events)
- `helm get values REL`, `helm history REL`
- `helm upgrade REL ./chart -f values-track.yaml --wait`
- `for i in $(seq 100); do curl -s http://svc/; done | sort | uniq -c` from a pod

## Common mistakes
- Scaling Deployments with `kubectl scale`: the next `release.sh` resets it, silently moving the split again.
- Fixing the canary and forgetting that the percentage depends on the stable replica count.
- Relying on pod count instead of the Service endpoints.

## Postmortem
Root causes: label override copied into canary values; a probe path from another service; replica count left at the
default. Contributing factors: no check that a canary receives *some* but not *too much* traffic; `failed` release state ignored.
Prevention: add a post-deploy check of endpoint counts per track, keep selector labels out of per-track values, and make
canary weight an explicit computed value in the pipeline.

## Helm 3 vs Helm 4
No behavioural difference. `--wait` timing and the resulting `failed` record are the same; Helm 4's default `--wait`
strategy waits for readiness of the rendered resources, as in Helm 3.
