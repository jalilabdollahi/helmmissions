# "false" Is True

## What broke
`ingress.enabled` was written as `"false"` - a quoted YAML string. The template guard
`{{- if .Values.ingress.enabled }}` only asks "is this value truthy?", and in Go templates every non-empty
string is truthy. So the Ingress was rendered on every deploy, no matter how convincingly the file said "false".

## Why Helm behaves this way
Helm does not coerce types for you. YAML decides the type: `false` is a boolean, `"false"` and `'false'`
are strings. Go's template engine treats the empty string, `0`, `nil`, empty lists/maps and boolean `false`
as false, and everything else as true. That makes the quoted word "false" a perfectly valid, perfectly
truthy string. The same trap exists for `"0"`, `"no"` and `"off"`.

## The fix
Remove the quotes (`enabled: false`) and run `helm upgrade`. From the command line, `--set ingress.enabled=false`
also yields a boolean, but `--set-string ingress.enabled=false` deliberately stays a string and would
keep the bug alive.

## In real life
Values often pass through other tools before reaching Helm: shell variables in CI (`--set x=$FLAG` is
fine, but `--set-string` is not), templating of values files with envsubst, Terraform's `helm_release`
blocks, or ArgoCD parameters (which are strings by default). Each hop is a chance for `false` to become
`"false"`. Charts that care can defend themselves with `{{ if eq (toString .Values.ingress.enabled) "true" }}`,
and a `values.schema.json` with `"type": "boolean"` turns the mistake into an install-time error.

## Commands worth remembering
- `helm get values <rel> --all -o json | jq .ingress` - JSON output shows the real type (`"false"` vs `false`)
- `helm template ./chart | grep -c 'kind: Ingress'` - quick check of what a values change does
- `helm lint ./chart` - catches schema violations if the chart ships a schema

## Common mistakes
- Deleting the Ingress with `kubectl`: the release still owns it and the next upgrade brings it back.
- Fixing the template instead (`if eq .Values.ingress.enabled "true"`): hides the mistake and breaks
  everyone who passes a real boolean.
- Using `--set-string` for booleans.

## Helm 3 vs Helm 4
No difference: both treat the quoted string as truthy.
