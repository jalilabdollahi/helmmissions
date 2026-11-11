# Connection Refused

## What broke
The Service forwarded traffic to `targetPort: 8080`, but nginx listens on 80. Pods were Ready and the
Service had endpoints, so every dashboard was green - and every connection was refused.

## Why Helm behaves this way
Helm renders exactly what the values say; it has no idea what port your image listens on. The
relationship between a Service and its pods has three parts that are easy to mix up:
- `selector` decides which pods become endpoints (it worked here);
- `port` is the port callers connect to on the Service;
- `targetPort` is the port on the pod that receives the traffic (a number or the *name* of a container port).
Readiness probes check the container's own port, not the Service, so a wrong targetPort never makes a
pod unready.

## The fix
Correct `service.targetPort` in `values.yaml` (or better, reference the named port `http`, which keeps
Deployment and Service in sync) and `helm upgrade`. A `kubectl patch svc` would work for a minute, but the
release record and the chart would still say 8080; the next upgrade, or Helm's three-way merge, would
bring the bug back.

## In real life
This is the classic "everything is Ready but nothing works" bug, often introduced when an image changes
its listening port (nginx to nginx-unprivileged, 80 to 8080) and only one place is updated. Using
`targetPort: http` with a named `containerPort` removes the duplicated number. Test from a pod, not from
your laptop: `kubectl run` with curl, or `kubectl port-forward` to the Service.

## Commands worth remembering
- `kubectl get endpoints <svc>` / `kubectl get endpointslices -l kubernetes.io/service-name=<svc>`
- `kubectl describe svc <svc>` - shows Port, TargetPort and Endpoints together
- `kubectl port-forward svc/<svc> 8080:80` - quick manual test
- `helm get manifest <rel> | grep -B2 -A6 'kind: Service'`

## Common mistakes
- Assuming endpoints present means the Service works.
- Changing `port` (what callers use) instead of `targetPort`.
- Patching the Service live and forgetting the chart.

## Helm 3 vs Helm 4
No difference. Helm 4 applies new releases with server-side apply by default, but a manual change to a field
Helm renders from values is still overwritten (or flagged) on the next upgrade.
