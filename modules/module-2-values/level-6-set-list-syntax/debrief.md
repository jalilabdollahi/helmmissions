# Commas In --set

## What broke
The runbook used `--set dnsSearch=payments.svc.cluster.local,corp.internal`. In Helm's `--set` syntax the comma
separates independent `key=value` assignments, so everything after the first comma was parsed as a new key
(`corp.internal`) that never gets a value: `failed parsing --set data: key "internal" has no value`.

## Why Helm behaves this way
`--set` is a compact assignment language: `a.b=c` nests, `a[0]=x` indexes, `a={x,y}` builds a list and `,`
chains several assignments. Because the comma is syntax, a literal comma in a value has to be escaped (`\,`),
and a list has to be written with braces or indexes. The escape hatch works for strings only: it
produces one string `"a,b"`, which Kubernetes rejects for a list-typed field such as `dnsConfig.searches`.

## The fix
`--set 'dnsSearch={payments.svc.cluster.local,corp.internal}'` (quoted so the shell does not brace-expand or
glob), or indexes, or a values file with a YAML list. Always check what the pods really got:
`kubectl get deploy mesh-client -o jsonpath='{.spec.template.spec.dnsConfig.searches}'`.

## In real life
Runbooks and CI pipelines love one-line `--set` flags; lists of hostnames, tolerations, CIDRs and
`extraArgs` are exactly where they break. Past a handful of values, a values file reviewed in a pull
request beats a long command line. `--set-json` (`--set-json 'dnsSearch=["a","b"]'`) is a good middle
ground for structured values on the command line.

## Commands worth remembering
- `helm template ./chart --set 'list={a,b}' | grep -A4 searches` - verify the shape without installing
- `helm get values <rel> -o yaml` - shows lists as lists, strings as strings
- `--set-json` - pass a JSON fragment when `--set` syntax gets awkward

## Common mistakes
- Escaping the comma and getting one string: the API server then rejects the type, or worse, a chart
  without validation silently accepts it.
- Forgetting shell quoting around `{...}` or `[...]`.
- Passing the same list in `--set` and in a values file: `--set` replaces list values entirely, it does not merge.

## Helm 3 vs Helm 4
Same `--set` grammar and the same error text in both.
