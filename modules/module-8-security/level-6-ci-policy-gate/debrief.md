# The Policy Gate

## What broke
The chart was functionally fine but violated three house rules enforced by `ci/policy.sh`: a floating image tag
(`nginx:latest`), containers without cpu/memory limits, and containers without readiness and liveness probes.
Because the gate inspects the *rendered* manifests of every container, the log-shipper sidecar failed too.

## Why Helm behaves this way
Helm does not judge manifests; it renders and applies them. Policy lives next to Helm: `helm template` produces
the exact objects that would hit the cluster, so a CI job can read them with `jq`, `conftest`, `kubeconform` or
Kyverno CLI and block the merge. The gate checks the render, not the templates, because values, `with` blocks and
helpers decide what ships. Fixes therefore go into the chart (values and templates), never into the gate.

## The fix
Pin the tag, set limits in values for each container, add the missing probes in the template, and run the gate until it
prints `policy gate passed`; then `helm upgrade --install`. A passing local gate proves nothing about the cluster
until the release is actually deployed from that chart.

## In real life
`:latest` makes rollbacks meaningless (the "previous" version is whatever was pulled last) and lets a registry push
change production silently. Missing limits let one noisy pod starve a node and break QoS guarantees; missing
probes mean Kubernetes routes traffic to pods that are not ready and never restarts a wedged process. Teams often
meet these through an admission controller (Kyverno, Gatekeeper) rejecting a deploy at 2 a.m. — shifting the same rule
left into CI turns that into a failed merge request. The anti-pattern is "fixing" the gate: adding an exemption, loosening
a regex or skipping the job. Policy owners should own the gate (CODEOWNERS) so that cannot happen quietly.

## Commands worth remembering
- `helm template NAME ./chart | jq`-style pipelines — inspect the render (convert YAML first)
- `helm lint ./chart --strict`
- `kubectl get deploy NAME -o yaml | grep -A5 -E 'limits|Probe'`
- `kubectl describe pod` — shows probe failures and QoS class

## Common mistakes
- Pinning the tag in one container and forgetting the sidecar or initContainer.
- Adding limits only under `requests` (or only memory) — the rule needs both cpu and memory limits.
- Weakening or bypassing `ci/policy.sh` to get a green pipeline.
- Passing the gate locally but never running `helm upgrade`, so the cluster still runs the old release.
