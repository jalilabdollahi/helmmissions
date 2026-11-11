# 256 Bytes Of RAM

## What broke
`limits.memory: 256` has no unit. Kubernetes quantities are plain numbers of bytes unless a suffix is given, so the limit
was 256 bytes - far below the 128Mi request. The API server validates that requests never exceed limits and rejected the
Deployment, so the release ended in the `failed` state with no pods at all.

## Why Helm behaves this way
Helm renders whatever the values contain: `256` became the integer `256` in the manifest. The meaning is decided later,
by the Kubernetes API: `256` = bytes, `256Mi` = 256 mebibytes (2^20 bytes), `256M` = 256 megabytes (10^6), `0.25Gi` is
also valid. CPU works the same way (`1` core, `500m` millicores). If the request had been omitted, the Deployment would have
been accepted and the container would have been OOM-killed or stuck at start-up instead of being rejected - a much harder
failure to diagnose.

## The fix
Write the unit: `memory: 256Mi`, then `helm upgrade`. A first revision in `failed` state can be upgraded directly; no need
to uninstall.

## In real life
Typos in resource units are common (`256` vs `256Mi`, `1gb` vs `1Gi`, `100m` vs `100M` for memory), and they surface differently
depending on request/limit combinations: API rejection, `OOMKilled`, scheduling failures (`Insufficient memory`). Teams guard
against them with `values.schema.json` patterns, LimitRange/ResourceQuota objects, policy engines (Kyverno, Gatekeeper) and
`helm template | kubeconform` in CI.

## Commands worth remembering
- `helm history <rel>` / `helm status <rel>` - failed revisions keep the API error
- `kubectl get deploy <name> -o jsonpath='{.spec.template.spec.containers[0].resources}'` - what the cluster really got
- `kubectl describe pod` - look for `OOMKilled` (exit code 137) or `FailedScheduling`

## Common mistakes
- Using `kubectl set resources` or `kubectl edit` to push the right number: Helm values still say `256`.
- Mixing up `M` and `Mi`, or using `Mb`/`MB`, which are not valid Kubernetes suffixes.
- Raising the limit but forgetting the request, leaving the pod badly scheduled.

## Helm 3 vs Helm 4
The Kubernetes validation is the same. The message differs in wording: Helm 4 applies manifests with server-side apply by default, so
the error reads `server-side apply failed for object ...`; Helm 3 reports `Deployment.apps "..." is invalid` after a client-side create.
Both leave a `failed` revision that `helm upgrade` can recover from.
