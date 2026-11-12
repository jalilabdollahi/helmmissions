# Root Is Not Welcome

## What broke
The pod spec asked for `runAsNonRoot: true`, but the container image (`nginx:1.27-alpine`) declares no non-root `USER`,
so its process would start as UID 0. The kubelet checks that before starting the container and fails it with
`CreateContainerConfigError: container has runAsNonRoot and image will run as root`. The release was "deployed" and the
pods never ran.

## Why Helm behaves this way
Helm only wrote the manifest the chart described. The conflict between a pod-level security setting and a property of the
image is detected at container creation time by the kubelet, long after the API server accepted the Deployment. The
kubelet can only verify `runAsNonRoot` when the image's `USER` is numeric, or when you set `runAsUser` explicitly.

## The fix
Keep the guard and change the workload to something that can obey it: an image built for an unprivileged user
(`nginxinc/nginx-unprivileged` runs as UID 101) and a port above 1024 (8080). Update the container port, and keep the
Service targeting the named port so clients are unaffected.

## In real life
A root container that escapes isolation is root on the node; `runAsNonRoot` is one of the cheapest hardening steps and
part of the Pod Security Standards "restricted" profile. Teams hit this when a base image changes, or when someone turns
the control on cluster-wide and old charts break. The tempting fixes are removing the setting or forcing `runAsUser: 0`,
which defeats the point, or forcing a random UID on an image that cannot write its own directories or bind port 80 — the
pod then crash-loops instead.

## Commands worth remembering
- `kubectl describe pod` — the Events section names the kubelet's reason
- `docker image inspect IMAGE --format '{{.Config.User}}'`
- `kubectl exec POD -- id` — prove what the process runs as
- `kubectl get pod POD -o jsonpath='{.spec.securityContext}'`

## Common mistakes
- Removing `runAsNonRoot` (or setting it to false) to get the pod to start.
- Setting `runAsUser: 1000` on an image that expects root: it fails on file permissions or on port 80.
- Changing the image but not the container port/probe, so the readiness probe hits a closed port.
