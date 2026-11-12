# 1.10 Became 1.1

## What broke
`appVersionLabel: 1.10` was written without quotes, and YAML reads `1.10` as the floating-point number 1.1. The trailing zero
vanished before any template ran, so pods were labelled `app.version=1.1` and dashboards mixed release train 1.10 with the old 1.1.
Nothing failed - the label is a valid string either way - which is what makes this bug survive in production.

## Why Helm behaves this way
Helm hands the values file to a YAML parser, which types each plain scalar: `1.10` is a float, `1` an integer, `true` a bool,
`"1.10"` a string. Helm cannot recover the original spelling. On the command line the rules are Helm's own: `--set` converts only
integers, booleans and `null` (so `--set v=1.10` stays the string "1.10"), while `--set-string` never converts anything. `--set-file`
and `--set-json` are the other typed variants. Verified on Helm 4.3: a values-file `1.10` becomes 1.1, `--set appVersionLabel=1.10` stays "1.10".

## The fix
Quote the string in the values file (`appVersionLabel: "1.10"`), or use `--set-string appVersionLabel=1.10` in the deploy command, then redeploy.
A pod template change rolls the pods; relabelling live pods would be lost at the next rollout.

## In real life
Anything that looks like a number but is an identifier must be a string: versions (`1.10`, `2.0`), image tags (`1.20`, `3`), build
numbers with leading zeros, ZIP codes, phone numbers, port names. A `values.schema.json` with `"type": "string"` for these keys would have
turned this into an install-time error. Also quote versions in `Chart.yaml` `appVersion`.

## Commands worth remembering
- `helm get values <rel> -o json` - JSON shows `1.1` (number) versus `"1.10"` (string)
- `helm template ./chart -f values.yaml | grep app.version` - check what will be labelled
- `kubectl get pods -L app.version` - show a label as a column

## Common mistakes
- Fixing the file but not redeploying (the cluster still shows 1.1).
- Relabelling pods with `kubectl label`: gone on the next rollout, and the Deployment disagrees.
- Quoting at the shell level only (`--set v="1.10"`): the shell removes the quotes before Helm sees them; `--set-string` is the real control.

## Helm 3 vs Helm 4
The same in both versions. Note that, unlike what many blog posts claim, `--set x=1.10` does not turn into a float in either; only values files
(YAML) do that.
