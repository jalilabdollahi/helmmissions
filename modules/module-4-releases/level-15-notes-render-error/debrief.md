# Broken NOTES.txt

## What broke
`templates/NOTES.txt` referenced `.Values.ingress.host`, but the chart's `values.yaml` has no `ingress` section.
`.Values.ingress` is nil, and accessing a field of nil is a template error. Helm renders NOTES.txt together with
every other template, so the install aborted before any object reached the cluster.

## Why Helm behaves this way
NOTES.txt is an ordinary template (it has access to `.Values`, `.Release` and `.Chart`) whose output is printed
after install/upgrade and stored in the release (`helm get notes`). Because it is part of the render step, an error in it fails
the whole install, exactly like an error in a Deployment template. That is a feature: it is better to fail early
than to deploy and print a broken hint. The error message gives the file, line and column. No release record is
written, because rendering happens before the release is created, so there is nothing to clean up.

## The fix
Give the value a default in `values.yaml`, or write NOTES.txt defensively (`{{ if .Values.ingress }}`, `default`,
`dig`). Then install and read `helm get notes`.

## In real life
NOTES.txt files get copied from `helm create` scaffolds, where they reference ingress, NodePort and
LoadBalancer values, and are rarely tested. They also fail only on specific value combinations (ingress disabled,
service type changed). Running `helm template` and `helm lint` with each environment's values file in CI catches this
before a deploy does.

## Commands worth remembering
- `helm template <rel> ./chart --show-only templates/NOTES.txt` — render just the notes
- `helm get notes <rel>` — notes of an installed release
- `helm lint ./chart -f values-prod.yaml` — lint with real values
- `{{ dig "ingress" "host" "" .Values.AsMap }}` — nil-safe lookups of nested values

## Common mistakes
- Deleting NOTES.txt to silence the error and losing the user-facing instructions.
- Testing only with default values, then failing in an environment with different values.
- Adding `{{ required }}` to NOTES, so a missing optional value blocks deployment.

## Helm 3 vs Helm 4
Identical behaviour: NOTES.txt errors fail the install and leave no release record. The error text format is the
same (`template: <chart>/templates/NOTES.txt:<line>:<col>: executing ...`).
