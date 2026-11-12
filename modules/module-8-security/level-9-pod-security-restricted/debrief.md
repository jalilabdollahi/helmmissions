# Restricted Pod Security

## What broke
The namespace enforces the Pod Security Standards `restricted` profile through Pod Security Admission (PSA). The chart's pod
spec set none of the hardening fields, so the admission controller rejected every pod the ReplicaSet tried to create and listed
what was missing: `allowPrivilegeEscalation != false`, unrestricted capabilities, `runAsNonRoot != true` and no seccomp profile.
Init containers are checked exactly like regular containers.

## Why Helm behaves this way
PSA is a built-in admission plugin driven by namespace labels (`enforce`, `audit`, `warn`). It validates *pods*, not
Deployments, so Helm's apply of the Deployment succeeds and the rejection surfaces later as a ReplicaSet `FailedCreate`
event: `helm install` says deployed, `kubectl get pods` is empty. Settings can live at pod level (`runAsNonRoot`,
`seccompProfile`) or container level (`allowPrivilegeEscalation`, `capabilities`); the check passes when each container is
covered by one of them.

## The fix
Harden the pod spec in the chart: non-root user, `allowPrivilegeEscalation: false`, `capabilities.drop: ["ALL"]`,
`seccompProfile.type: RuntimeDefault`, for every container including initContainers and sidecars; then upgrade. Keep the
namespace label as it is.

## In real life
Platform teams roll `restricted` out namespace by namespace, often first with `warn`/`audit` labels and then `enforce`,
and charts written years ago break. Third-party charts frequently miss the init container or a sidecar. The two quick-and-dirty
"fixes" are relabelling the namespace `privileged` (or deleting the label) and sprinkling `privileged: true`; both silently
remove a control that stops container escapes, and security tooling will find them later. Use
`kubectl label ns X pod-security.kubernetes.io/warn=restricted --dry-run=server` to see what would break before you enforce.

## Commands worth remembering
- `kubectl get ns NS --show-labels` / `kubectl describe rs` — the policy and the rejection reason
- `kubectl label ns NS pod-security.kubernetes.io/warn=restricted --overwrite` — rehearse a stricter level
- `helm template ./chart | kubectl apply --dry-run=server -f - -n NS` — PSA runs on pods only, so also check the RS events
- `kubectl auth can-i` is irrelevant here: PSA is admission, not RBAC

## Common mistakes
- Hardening only the main container; the init container or a sidecar still violates the profile.
- Setting `runAsNonRoot: true` on an image that runs as root (the pod then fails with CreateContainerConfigError).
- Weakening the namespace label instead of fixing the pod spec.

## Helm 3 vs Helm 4
No difference in the cause. With `--wait` (or `--rollback-on-failure` on Helm 4, `--atomic` on Helm 3) the install would
have timed out instead of reporting `deployed`, which is why CI should always wait. On Helm 4, server-side apply reports
admission errors for the Deployment itself as `server-side apply failed for object ...`; PSA rejects the *pods*, so you see it in
the ReplicaSet events instead. Kubernetes v1.37 here: Pod Security Admission is built in and `restricted:latest` is evaluated.
