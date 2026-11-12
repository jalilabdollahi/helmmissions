# The Vanishing Config File

## What broke
`.Files.Get "files/site.conf"` returned an empty string. The chart's `.helmignore` contained `*.conf` (added to keep
experiments out of packages), and Helm applies `.helmignore` while *loading* the chart directory - the matching file is
never part of the chart object, so `.Files` cannot see it. nginx started with an empty `default.conf`, had no server
block to listen on, and the readiness probe never succeeded.

## Why Helm behaves this way
`.helmignore` works like `.gitignore` for charts. It is honoured by `helm package`, but also by every command that reads
a chart directory (`install`, `upgrade`, `template`, `lint`). Anything it excludes is not in `.Files`, `.Files.Glob`,
`.Files.Get` or `.Files.Lines`. A missing file is not an error for `.Files.Get` - it returns `""` - so a typo in the path
and an ignored file look the same: silently empty. (Also remember that `templates/` is rendered, while `files/` and any
other directory is only available through `.Files`.)

## The fix
Remove or narrow the `*.conf` pattern, then upgrade so the ConfigMap changes; the checksum annotation on the pod
template (`sha256sum` of the rendered ConfigMap) makes the Deployment roll out the new config automatically.

## In real life
This bites when a `.helmignore` is copied from another repo or grows "just for packaging", and when a pattern like
`*.yaml`, `*.json`, `*.conf` is added to hide fixtures. Everything works in review (the file is in git) and fails only
in the cluster. A CI check that renders the chart and verifies the ConfigMap is not empty, or `helm lint --strict`
plus a golden-file comparison, catches it.

## Commands worth remembering
- `ls -a ./chart` - dotfiles included; `cat ./chart/.helmignore`
- `helm template <rel> ./chart -s templates/configmap.yaml` - what `.Files.Get` really produced
- `helm package ./chart && tar tzf <chart>.tgz` - which files made it into the package

## Common mistakes
- Hot-fixing the live ConfigMap with `kubectl`: the pod recovers, but the next upgrade writes the empty file back.
- Checking only that the file exists in the repo, not that Helm can see it.
- Using `.Files.Get` with a path relative to `templates/` - paths are relative to the chart root.

## Helm 3 vs Helm 4
Same behaviour. Note that `!`-negation patterns in `.helmignore` are best avoided: in Helm 4.3 a negated rule combined with
a wildcard made the chart fail to load with `Chart.yaml file is missing` in our tests, so prefer removing or narrowing patterns.
