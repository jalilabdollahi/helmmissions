# Read The Label

## What broke
Nothing was wrong with the chart; the player did not know its interface. A chart's configuration surface is
exactly the keys its templates read, and they are chosen by the chart author. `--set service.port=9100` was
a guess that Helm happily accepted and the templates never looked at, so the Service stayed on 80.

## Why Helm behaves this way
Every chart ships its defaults in `values.yaml`, usually with comments, and often a `README.md` and a
`values.schema.json`. They are part of the package, so `helm show values|readme|chart|all` work on a
`.tgz`, a directory, a repository reference or an OCI URL, with no need to unpack. Helm does not validate keys against the
templates: unknown keys are merged and ignored.

## The fix
Read `helm show values` (and the readme), find `telemetry.servicePort`, put the override into a values file
and install the archive with `-f`. A values file records the intent in a reviewable form next to the
chart; `helm get values` shows afterwards what was actually used.

## In real life
Third-party charts are black boxes you integrate: pin the version, read their values, keep your overrides
in your own repository, and never edit the vendor's package. `helm show values > base.yaml` is the usual
starting point for an environment file. Diff the defaults between chart versions before upgrading, because
keys get renamed.

## Commands worth remembering
- `helm show values <chart|tgz|repo/chart|oci://...>` - defaults and their comments
- `helm show readme <chart>` / `helm show chart <chart>` / `helm show all <chart>`
- `helm pull <chart> --untar` - unpack when you really need the templates
- `helm template <chart> -f my-values.yaml | grep -A4 'kind: Service'` - check your key works before installing

## Common mistakes
- Guessing key names (`service.port`, `port`, `servicePort`) instead of reading the values.
- Editing the vendor package or its `values.yaml` instead of overriding it.
- Using only `--set`, so the override is not stored anywhere reviewable.

## Helm 3 vs Helm 4
`helm show ...` and `-f` behave the same. Charts with a `values.schema.json` that forbids unknown keys
would reject the wrong guess in both versions.
