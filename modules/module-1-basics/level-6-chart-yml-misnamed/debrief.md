# Chart.yml Is Not Chart.yaml

## What broke
The chart's metadata file was called `Chart.yml`. Helm locates a chart by looking for a file named exactly
`Chart.yaml`; without it the directory is just a folder with some YAML in it. Everything inside - templates,
values, even a perfectly valid `Chart.yml` - is ignored until the name is right.

## Why Helm behaves this way
Helm's chart format is a convention of fixed names: `Chart.yaml`, `values.yaml`, `values.schema.json`,
`templates/`, `charts/`, `crds/`, `.helmignore`. The loader does not guess alternatives, because
ambiguity (`Chart.yml`, `chart.yaml`, both?) would make packaging and provenance unreliable. The
extension of your own files inside `templates/` is more flexible (`.yaml`, `.yml`, `.tpl`), but the
well-known files are exact and case-sensitive.

## The fix
Rename the file to `Chart.yaml` - rename, not copy: a second `Chart.yml` left behind is confusing, and
`helm package` would bundle it. Lint, then install.

## In real life
This shows up when charts are hand-written on case-insensitive file systems (macOS, Windows), hand-copied
between repositories, or produced by tooling that normalises extensions to `.yml`. A chart that "worked on my
laptop" with `chart.yaml` fails in Linux CI. `helm lint` in the pipeline catches it before the deploy.

## Commands worth remembering
- `helm lint ./chart` - verifies the chart structure and metadata
- `helm show chart ./chart` - prints the parsed Chart.yaml
- `ls -la ./chart` - look at real names, including case and extension
- `helm create demo` - scaffold a correct layout to compare with

## Common mistakes
- Copying instead of renaming, leaving two metadata files.
- Fixing the extension but getting the case wrong (`chart.yaml`).
- Debugging the templates when the chart is not even recognised.

## Helm 3 vs Helm 4
Both refuse the chart. The wording differs: Helm 3 says "Chart.yaml file is missing"; Helm 4 reports
"unable to detect chart at .../Chart.yaml: open ...: no such file or directory" for `helm install`, and
`helm lint` reports "unable to check Chart.yaml file in chart".
