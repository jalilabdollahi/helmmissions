# Unclosed Action

## What broke
A single missing brace: `{{ .Values.site.name }</h1>` instead of `{{ .Values.site.name }}`. Helm's template
engine (Go's `text/template`) scans every file under `templates/` for `{{ ... }}` actions. An action that is
opened but not closed correctly is a *parse error*, and a parse error aborts the whole render - not a single
template, the entire release.

## Why Helm behaves this way
Rendering happens in two phases: first every template is parsed, then executed against the values. Syntax
mistakes (unclosed actions, unbalanced `if`/`end`, unknown functions) are caught in the parse phase, which is
purely local: no API call is made, no release record is created, nothing half-installed is left behind. That is
why the error message names the chart-relative file and line (`pressroom/templates/configmap.yaml:13`) and why
`helm template` and `helm lint` reproduce it instantly without a cluster.

## The fix
Close the action with `}}`. Keep the value reference - hard-coding the site name would silence the error but
break the contract that the chart is configured through `values.yaml`.

## In real life
Parse errors are the cheapest failures a pipeline can have, so make them fail early: run `helm lint` and
`helm template` in the pull-request job, before any deploy job gets a kubeconfig. Editors with a Go-template
or Helm plugin highlight unbalanced braces as you type. In a big chart the line number is your friend - the
message counts lines of the template file, not of the rendered output.

## Commands worth remembering
- `helm template <name> ./chart` - render locally; parse errors show up here first
- `helm lint ./chart` - parse + structural checks
- `helm template ./chart --debug` - also prints the partially rendered manifest on execution errors
- `helm install --dry-run=client` - same render, plus release metadata

## Common mistakes
- "Fixing" the line by typing the literal value: the install works but `--set site.name=...` stops working.
- Looking at the Kubernetes side (`kubectl get events`) - nothing was ever sent, so there is nothing to see there.
- Confusing parse errors (`parse error at ...`) with execution errors (`executing "..." at <...>`); the first
  are syntax, the second are about data.

## Helm 3 vs Helm 4
Identical behaviour in both: the text of the parse error comes from Go itself, and neither version creates a
release record when the render fails.
