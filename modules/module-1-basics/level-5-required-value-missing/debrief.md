# Required Means Required

## What broke
The Ingress template wraps the host in `required "..." .Values.ingressHost`. The chart's default for
`ingressHost` is an empty string, and `required` fails the render when a value is missing or empty. Helm
stopped before sending anything to the cluster and printed the author's message.

## Why Helm behaves this way
`required` is how chart authors turn "this value has no sane default" into a clear error, instead of
producing an Ingress with an empty host (which would be accepted and silently match every request) or a
cryptic Kubernetes validation error later. The message is yours to write, so it should say what to set.
Helm evaluates it at render time, which means `helm template` and `helm lint --set ...` fail the same way
without a cluster.

## The fix
Supply the value where environment-specific settings belong: a values file per environment
(`values-staging.yaml`, `values-prod.yaml`), passed with `-f`. The file is reviewable, versioned and
repeatable; the chart keeps generic defaults so every environment is forced to make a conscious choice.

## In real life
Production incidents love defaults that "work": a hostname of `example.com`, a replica count of 1, an
empty password. `required` makes the safe behaviour the default one. The flip side: CI that installs the
chart with no values, for a smoke test, must pass test values (`ci/values.yaml`) or it will always fail.
`helm install -f values-staging.yaml` also records the values in the release, so `helm get values` shows
what the environment was deployed with.

## Commands worth remembering
- `helm show values ./chart` - defaults and their comments
- `helm install rel ./chart -f values-staging.yaml` - repeatable environment config
- `helm get values rel` - what the release was installed with
- `helm template ./chart -f values-staging.yaml | grep -A3 host` - preview

## Common mistakes
- Editing the chart's `values.yaml` for one environment: the next environment inherits it.
- Using only `--set ingressHost=...`: it works but nothing in git records it; a rerun forgets it.
- Setting the value to a placeholder just to silence the error.

## Helm 3 vs Helm 4
`required` works identically. The error text is prefixed with `execution error at (<template>:<line>:<col>)`
in both versions.
