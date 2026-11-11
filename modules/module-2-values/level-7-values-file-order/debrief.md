# Last One Wins

## What broke
`deploy.sh` passed `-f values-prod.yaml -f values-base.yaml`. When several values files set the same key, Helm
merges them left to right and later files overwrite earlier ones, so the generic base file (1 replica, debug logs)
silently beat the production file (3 replicas, warn logs). Nothing failed - the deploy was perfectly valid, just wrong.

## Why Helm behaves this way
Helm builds the final values in layers: the chart's `values.yaml`, then every `-f` file in command-line order, then
`--set`/`--set-string`/`--set-file`/`--set-json` flags. Maps merge key by key, scalars and lists are replaced by
the later layer. There is no notion of "this file is more specific" - position is the only priority, which is why
the order is part of the deployment's behaviour and belongs in version control.

## The fix
Put the general file first and the most specific last: `-f values-base.yaml -f values-prod.yaml`. The order matters in
the script, not in the values files, so editing the files to match would leave the next environment broken.

## In real life
Multi-environment setups (base + env + region + cluster) multiply this risk: one reordered line in a pipeline can drop
production to one replica or leave debug logging on. Review `helm get values <rel> --all` after a values-layout change,
keep the order in one place (a Makefile, deploy script or GitOps manifest), and use `helm template` in CI to assert the
rendered replica count and log level.

## Commands worth remembering
- `helm get values <rel> --all` - the merged result Helm actually used
- `helm template ./chart -f a.yaml -f b.yaml | grep replicas` - preview a particular order
- `helm upgrade --install` - idempotent deploy command for pipelines

## Common mistakes
- Fixing the symptom by editing the base file; the layering is still wrong.
- Running the correct command once by hand and leaving the script broken.
- Expecting lists to merge: a later list replaces the earlier one completely.

## Helm 3 vs Helm 4
The merge order and semantics are identical in Helm 3 and Helm 4.
