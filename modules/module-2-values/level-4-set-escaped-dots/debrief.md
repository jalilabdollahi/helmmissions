# Dots In Keys

## What broke
Prometheus discovers pods through the annotation `prometheus.io/scrape: "true"`. The release was
deployed with `--set podAnnotations.prometheus.io/scrape=true`. Helm's `--set` parser reads every `.` as
"go one level deeper", so it built `podAnnotations: {prometheus: {io/scrape: true}}`. The chart then
rendered the nested map as a string under the key `prometheus` and nothing complained.

## Why Helm behaves this way
`--set` is a path expression: `a.b[0].c=v` addresses a position in the values tree. Dots must therefore
be escaped when they belong to the key (`\.`), and commas, brackets and backslashes need care too. Quoting for the
shell matters as well: in zsh and bash an unquoted backslash is eaten before Helm ever sees it.
In a YAML values file none of this applies - a key is whatever the YAML says it is.

## The fix
`--set 'podAnnotations.prometheus\.io/scrape=true'` (and the same for `port`), or put the annotations in a
values file and use `-f`. Do not combine the fix with `--reuse-values`: the stale `prometheus` map from the
broken deploy would be merged back in.

## In real life
Annotation and label keys with dots and slashes are everywhere: `prometheus.io/*`, `cert-manager.io/*`,
`nginx.ingress.kubernetes.io/*`, `service.beta.kubernetes.io/aws-load-balancer-*`. Typing them into `--set`
is a classic source of silently-wrong manifests. Teams keep these in values files under version control,
and CI compares `helm template` output with expectations.

## Commands worth remembering
- `helm get values <rel> -o yaml` - shows the tree Helm built from your `--set` flags
- `helm template ./chart --set ... | grep -A5 annotations` - preview the effect before deploying
- `--set-json 'podAnnotations={"prometheus.io/scrape":"true"}'` - JSON syntax sidesteps path escaping

## Common mistakes
- Forgetting the quotes in the shell, so the backslash disappears and the dots are split again.
- Annotating pods with `kubectl annotate`: the next rollout loses it, because it is not in the pod template.
- Fixing the new key but keeping the old stale one via `--reuse-values`.

## Helm 3 vs Helm 4
Same escaping rules in both. `--set-json` exists in Helm 3.10+ and Helm 4 and is handy for this case.
