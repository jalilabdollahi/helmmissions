# Switch Back To Blue

## What broke
The chart keeps two Deployments (blue and green) in one release and routes traffic through the Service
selector `color: {{ .Values.activeColor }}`. Release 6.1 flipped `activeColor` to green in the same upgrade that
rolled green out, with an image tag that cannot be pulled and no `--wait` to notice. The Service pointed at
pods that would never be Ready, so every request failed while healthy blue pods sat idle.

## Why Helm behaves this way
Blue/green in Helm is just data: both colours are rendered every time, and one value chooses which one is
live. Because traffic is a single field of the Service, switching is an ordinary upgrade (revision 3) and is
reversible in seconds. A `helm rollback` to revision 1 would also move traffic, but it replays the whole old
manifest - including green's old state (0 replicas) - and the broken green would vanish before anyone could
debug it. Fixing forward by changing only `activeColor` keeps every other object exactly as it is.

## The fix
Set `activeColor: blue` where the pipeline reads it and upgrade without touching the green block. Do not use
`--wait` while green is intentionally unhealthy - Helm would mark the upgrade failed even though the switch
worked.

## In real life
Blue/green with Helm usually goes wrong at the cut-over: the flip is merged together with the new version,
readiness is not verified first, or the previous colour is torn down immediately so there is nothing to switch
back to. Good practice: deploy the idle colour with `--wait`, smoke-test it through its own Service or port-forward,
and only then flip the selector in a separate, tiny change.

## Commands worth remembering
- `kubectl get pods -L color` - which colour has which pods
- `kubectl get endpointslices -l kubernetes.io/service-name=<svc>` - does the Service have ready endpoints?
- `helm upgrade ... --set activeColor=blue` - flip traffic with one value
- `helm get values <rel>` - which colour the release thinks is live

## Common mistakes
- Patching the Service selector with kubectl: traffic recovers, but the next deploy flips it back.
- Rolling back and losing the failed colour you wanted to investigate.
- Combining "deploy new colour" and "switch traffic" in the same upgrade.

## Helm 3 vs Helm 4
Identical behaviour; a release applied by Helm 4 additionally records field ownership on the Service selector,
so a hand edit with kubectl can raise a field-manager conflict on the next upgrade.
