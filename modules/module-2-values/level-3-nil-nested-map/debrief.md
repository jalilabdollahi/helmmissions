# Nil Pointer In The Cache Block

## What broke
The ConfigMap template reads `.Values.cache.redis.host`. Staging's values have no `cache:` key, so
`.Values.cache` is nil, and asking nil for `.redis` is a hard error:
`nil pointer evaluating interface {}.redis`. The release is never created because rendering happens
before anything reaches the API server.

## Why Helm behaves this way
Values are a tree of maps. Reading a missing key from a map that exists is harmless - Go templates
return "no value" (Helm prints an empty string). But reading a key *through* a missing parent means
indexing into nil, and that is an error. The chart author tested with the prod values and never saw it.
Helm merges the values files you pass on top of the chart's own `values.yaml`; it never invents missing
parents for you.

## The fix
Make the template tolerate the absent block. The usual tools:
- `{{- with .Values.cache }}` / `{{- with .redis }}` - skip the whole section when the parent is missing
- `dig "cache" "redis" "host" "" .Values.AsMap` - safe deep lookup with a default
- an empty default block in the chart's `values.yaml` (`cache: {redis: {}}`) so the path always exists
`helm template ./chart` with and without the block proves both paths.

## In real life
Optional integrations (cache, tracing, external DB, SSO) differ per environment, and a nil-pointer error
usually appears the first time a *new* environment is created - often at the worst moment. Good charts
list every optional block with a default in `values.yaml`, guard it in templates, and run `helm template`
against a matrix of minimal and full values files in CI.

## Commands worth remembering
- `helm template ./chart -f values-x.yaml --debug` - render locally, with the failing template line
- `helm lint ./chart -f values-x.yaml` - lint with a specific environment's values
- `helm show values ./chart` - what the chart offers as defaults

## Common mistakes
- Adding a dummy `cache:` block to the staging file: the chart is still fragile for the next environment.
- Wrapping everything in `default` without guarding the parent: `default` does not help when the error
  happens while evaluating its argument.
- Forgetting that `with` rebinds `.`; use `$` for the root context inside the block.

## Helm 3 vs Helm 4
The error text and the behaviour are the same on both. Note that `.Values.AsMap` (used with `dig`)
is available in both.
