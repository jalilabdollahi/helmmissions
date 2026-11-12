# The Schema Says No

## What broke
`values.yaml` asked for `replicas: 0` and `logLevel: WARN`. The chart ships a `values.schema.json` that demands at least one
replica and one of four lower-case log levels. Helm validates the *merged* values against the schema on `install`, `upgrade`,
`template` and `lint`, and it refuses to continue when the rules are broken, listing every violation with its path.

## Why Helm behaves this way
A JSON Schema next to the chart is the chart author's contract: types, required keys, enums, ranges and patterns. Helm
evaluates it against the final computed values (defaults, `-f` files and `--set` flags all count), so a bad value is caught
before a single manifest is rendered, with a message that names the exact key. It is a guard rail, not a templating feature:
the schema does not change values, it only accepts or rejects them.

## The fix
Correct the values to satisfy the schema (`replicas: 2`, `logLevel: warn`). Never loosen the schema to make a deploy pass:
that file is the policy the platform team enforces for logging pipelines and availability. `--skip-schema-validation` exists for
rare legitimate cases (a schema bug, a staged migration) but turns every guard rail off for that command.

## In real life
Schemas pay off most in shared, multi-team charts: they prevent `"false"`-style type errors, typos in enum values and
out-of-range numbers long before Kubernetes sees them. Run `helm lint -f values-<env>.yaml` for each environment in CI so a
bad values file fails the pull request instead of the deployment.

## Commands worth remembering
- `helm lint ./chart -f values-prod.yaml` - validate a specific environment against the schema
- `helm template ./chart` - fails the same way without touching the cluster
- `helm install --skip-schema-validation` - the escape hatch (use sparingly, and say so in the PR)

## Common mistakes
- Editing `values.schema.json` until the error disappears.
- Using `--skip-schema-validation` in CI: later upgrades without the flag fail again, and the bad values may already be live.
- Fixing only the first error: Helm reports all violations at once, so read the whole list.

## Helm 3 vs Helm 4
Both validate on install, upgrade, lint and template. Helm 4 words the errors as `at '/replicas': minimum: got 0, want 1` (a newer
JSON Schema library); Helm 3 prints `- replicas: Must be greater than or equal to 1`. The `--skip-schema-validation` flag exists in Helm 3.16+ and Helm 4.
