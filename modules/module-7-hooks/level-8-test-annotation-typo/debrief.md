# "No Tests Found"

## What broke
The chart's test pod was annotated `"helm.sh/hook": tests` (plural). The valid hook names are `pre-install`, `post-install`,
`pre-upgrade`, ..., and `test`. Helm does not reject an unknown name: it logs a quiet `skipping unknown hooks` message and drops the
resource. The pod was therefore not created at install time, not part of the release manifest, and not stored as a hook, so
`helm test` found nothing to run and exited with status 0 (`TEST SUITE: None`). A pipeline stage that only checks the exit code was green
for as long as the typo existed.

## Why Helm behaves this way
A test is just a hook with the special event `test`. Helm stores hook manifests inside the release revision, and `helm test <release>`
creates the stored test hooks on demand, waits for them to finish and records the result (visible in `helm status`). A
resource whose hook annotation matches no known event is not applied at all. Fixing the annotation in your chart directory changes
nothing for an existing release until an upgrade stores a new revision containing the corrected hook.

## The fix
Correct the annotation to `"helm.sh/hook": test`, run `helm upgrade` to store it, then `helm test --logs`. The legacy alias `test-success` still works,
but `test` is the current name. A good test pod uses `before-hook-creation` as delete policy, so re-running tests does not collide with
the previous run's pod.

## In real life
Tests that never run are worse than no tests. Guard against this in CI: after a deploy, assert that a release actually has a test
(`helm get hooks <rel> | grep -q 'helm.sh/hook.*test'`), and fail on "no tests found" if you expect some. Lint your chart: reading the
rendered hooks with `helm template` and `helm get hooks` takes seconds. Remember too that `helm test` also doesn't run during `install`: it is a
separate, repeatable step.

## Commands worth remembering
- `helm get hooks <release>` — shows the hooks (including tests) that the stored release has
- `helm test <release> --logs` — runs tests and prints their output
- `helm status <release>` — last test suite run, phase and timestamps
- `kubectl get pods -l app.kubernetes.io/component=test` — leftover test pods

## Common mistakes
- Treating exit code 0 from `helm test` as proof that tests ran.
- Fixing the file and re-running `helm test` without upgrading.
- Running an equivalent pod by hand with `kubectl run`: it is not part of the release and the gate stays empty.

## Helm 3 vs Helm 4
Both versions skip unknown hook names; Helm 4 prints `level=INFO msg="skipping unknown hooks"` (easy to miss in CI logs) and `helm test` on
a release without tests still exits 0 in both. `test-success` (legacy) and `test` behave the same in both versions.
