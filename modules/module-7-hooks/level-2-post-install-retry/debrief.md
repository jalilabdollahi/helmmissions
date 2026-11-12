# Too Impatient

## What broke
The smoke test for `payments-gateway` is a `post-install,post-upgrade` hook Job that calls the Service exactly once
(`backoffLimit: 0`). The gateway pod needs about ten seconds before its readiness probe passes, and a Service has no
endpoints until then. On a fresh environment the hook fired immediately after the manifests were submitted, got
"connection refused", failed, and Helm marked the whole release `failed` even though the gateway came up fine afterwards.

## Why Helm behaves this way
Hooks run at fixed points of the lifecycle. `post-install` means "after all resources have been loaded into Kubernetes",
which is not the same as "after everything is ready". Whether Helm waits for readiness in between depends on `--wait`
(Helm 4: when the flag is omitted it only waits for hooks to finish, `hookOnly`; Helm 3 does not wait at all). Helm always
waits for the hook itself and treats a failed Job as a failed release. So a post-install check must either run after
a readiness wait or be written to tolerate a workload that is still starting.

## The fix
Pick one: add `--wait` to the pipeline command so readiness is reached before post-install hooks run, or make the
smoke test retry (a loop with a deadline in the script, or a higher `backoffLimit`). A retry loop inside the script is
the most robust because it works no matter how the chart is installed. Keep `activeDeadlineSeconds` so a truly broken
gateway still fails the release in bounded time.

## In real life
Smoke tests that "work when you run them by hand" are the classic flaky pipeline step. They pass against long-lived
environments and fail on every preview environment or first deploy. Treat a hook like any client of a service
that is starting up: retry with a deadline, log each attempt, and fail clearly when the deadline passes.

## Commands worth remembering
- `helm upgrade --install <rel> <chart> --wait --timeout 2m` — wait for readiness before post hooks and for the release
- `kubectl logs job/<release>-smoke` — the hook's own output
- `helm get hooks <release>` — what is stored as a hook
- `kubectl describe job <name>` — backoffLimit and failure reasons

## Common mistakes
- `--no-hooks` in the pipeline: green builds, no smoke test, no safety net.
- Making the test unable to fail (`|| true`, `exit 0`) to get past the red build.
- Sleeping a fixed time ("sleep 15") instead of retrying: it flakes the day the warm-up takes 16 seconds.

## Helm 3 vs Helm 4
Without `--wait`, Helm 3 runs post-install hooks as soon as resources are created. Helm 4 defaults to waiting for
hooks only (`--wait=hookOnly`), which gives the same race for the workload. In both, `--wait` makes the install wait for
workload readiness first, and `helm status` shows the failed post-install hook as the release description.
