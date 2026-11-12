# Catch Typos With A Schema

## What broke
`values-prod.yaml` spelled `replicaCount` as `replicaCnt` and `periodSeconds` as `periodSecond`. Helm merged those keys into the release's
values and the templates simply never read them, so production ran with the chart defaults — one replica and the default probe period.
Nothing failed, nothing warned: "unknown value" is not an error in Helm unless the chart says so.

## Why Helm behaves this way
Values are free-form YAML; a chart's `values.yaml` is documentation plus defaults, not a contract. The contract is an optional
`values.schema.json` (JSON Schema) in the chart root. Helm evaluates it against the fully merged values on `install`, `upgrade`,
`template` and `lint`, and aborts before rendering when it does not match. JSON Schema permits extra properties unless an object
sets `"additionalProperties": false`, and that setting is per object, so nested maps like `image`, `resources` and `probes.readiness` must each be
closed. Free-form maps (`extraEnv`, `podAnnotations`) are deliberately left open with a value-type rule instead. Types catch the
other class of mistakes: `replicaCount: "3"` or `concurrency: many`.

## The fix
Describe every documented value, close the objects, run the real override files through `helm template` / `helm lint`, repair what
the schema reveals, and upgrade. The schema now protects every future override — CI included.

## In real life
Typos in overrides are one of the most common silent production misconfigurations (a misspelled `resources`, a wrong `ingress.enabled`).
Public charts (Bitnami, Prometheus community) ship schemas; internal platform charts should too, often generated from values with
tools such as helm-schema or `helm-values-schema-json`. Add `helm lint -f values-<env>.yaml` for every environment to CI, so a bad
override fails the pull request instead of the rollout. Be careful with `additionalProperties: false` on charts used as subcharts or
with `global` values: leave `global` open, or the parent's globals are rejected.

## Commands worth remembering
- `helm lint ./chart -f values-prod.yaml` — schema + template checks against an environment file
- `helm template ./chart --set a.b=c` — see the schema error without a cluster
- `helm get values REL [--all]` — what the release stored vs the computed result
- `helm show values ./chart` — the documented defaults

## Common mistakes
- Fixing the two typos and moving on: the next typo is silent again.
- Closing only the top level: `image.tagg` and `probes.readiness.periodSecond` still pass.
- Forgetting free-form maps and the `global` key, which then break legitimate values.

## Helm 3 vs Helm 4
Schema validation works the same in Helm 3.14+ and Helm 4 (the underlying validator was upgraded, so draft 2020-12 features such as
`$defs` and `$ref` are fine in both; the error wording differs slightly: `additional properties 'x' not allowed`).
