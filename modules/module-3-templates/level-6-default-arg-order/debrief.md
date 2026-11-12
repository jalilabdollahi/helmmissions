# Default Always Wins

## What broke
The image helper read `default .Values.image.tag .Chart.AppVersion`. Sprig's `default` takes the *fallback first*
and the value second: `default "fallback" .Value`. With the arguments swapped, the "value" is the appVersion,
which is never empty, so it always won and the pinned tag in values.yaml (and any `--set image.tag=`) was ignored.

## Why Helm behaves this way
`default` is an ordinary function, and Go templates pass arguments positionally. The odd order exists so that it
works at the end of a pipeline: `.Values.image.tag | default .Chart.AppVersion` pipes the value in as the *last*
argument. Swapped-argument bugs render without any error - the output is just consistently the "wrong" source of
truth, which looks like a values or Helm bug rather than a template bug.

## The fix
Put the fallback first (`default .Chart.AppVersion .Values.image.tag`) or use the pipeline form. Test all three
cases: a pinned tag, an overridden tag, and an empty tag.

## In real life
`helm create` generates `{{ .Values.image.tag | default .Chart.AppVersion }}` for exactly this reason. When someone
"simplifies" it by hand, the bug often lives for months because the appVersion is usually correct - until a
release candidate or a hotfix tag is pinned in values and nothing changes. The usual blast radius is a production
rollout to an unpublished image, or - worse - silently running an older tag than the one the change ticket says.

## Commands worth remembering
- `helm template ./chart --set image.tag=x | grep image:` - prove an override takes effect
- `helm get values <rel> --all` - computed values the release really received
- `helm get manifest <rel> | grep image:` - what was applied

## Common mistakes
- Adding `--set image.tag=v1.10` to every upgrade: it hides the chart bug and the next person forgets the flag.
- Removing `default` altogether and losing the appVersion fallback that other environments rely on.
- Remembering the order from other languages (`value or fallback`) - in Sprig it is `default fallback value`.

## Helm 3 vs Helm 4
`default` behaves identically (Sprig). In Helm 4, `helm status -o json` does not include the chart, use
`helm history` when checking which chart a release runs.
