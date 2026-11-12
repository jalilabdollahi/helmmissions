# Pull Backoff

## What broke
`values.yaml` said `tag: 1.27-alpien`. Helm rendered that string faithfully into the Deployment, the
release was recorded as `deployed`, and the kubelet then failed to pull an image that does not exist.
`ErrImagePull` quickly turns into `ImagePullBackOff` as the kubelet retries with growing delays.

## Why Helm behaves this way
Helm's job ends when the Kubernetes API accepts the manifests. Without `--wait`, `deployed` means "the
objects were created", not "the application works". Helm never validates that an image tag exists, a
Secret is present or a probe succeeds - that is the cluster's job, and the signal lives in pod events.
So troubleshooting a Helm release is two-layered: `helm get ...` for what was asked, `kubectl describe` for
what happened.

## The fix
Correct the tag in the chart's `values.yaml` and run `helm upgrade`. This creates revision 2; the
Deployment is rolled and the new pods pull the right image. The file in the repository, the Helm release
record and the live Deployment now all agree.

## In real life
Typos in tags, registries moved, tags overwritten or garbage-collected, missing `imagePullSecrets` -
the symptom is always the same. In CI use `--wait --timeout` (Helm 4: `--wait` is unchanged,
`--atomic` became `--rollback-on-failure`) so the pipeline goes red instead of green-with-broken-pods.
A `kubectl set image` hotfix feels faster but the next `helm upgrade` silently reverts it, because Helm
renders from values again.

## Commands worth remembering
- `kubectl describe pod <pod>` - the Events section names the failing image and reason
- `kubectl get events -n <ns> --sort-by=.lastTimestamp`
- `helm get values <rel> --all` - computed values the release actually used
- `helm get manifest <rel>` - the exact YAML Helm applied
- `helm upgrade <rel> ./chart --wait` - roll out and wait for readiness

## Common mistakes
- Using `kubectl set image` / `kubectl edit`: it fixes pods now and breaks the next upgrade.
- Fixing only with `--set image.tag=...` on the command line: the typo stays in `values.yaml`.
- Reading `STATUS: deployed` as "healthy".

## Helm 3 vs Helm 4
Identical behaviour. Helm 4 renames `--atomic` to `--rollback-on-failure`; either way, `--wait` is what
would have made the original install report the failure immediately.
