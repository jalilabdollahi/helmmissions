# Common Mistakes

## Mistake 1: Fixing the symptom, not the chart
It is tempting to patch live resources with kubectl and stop there, but this level is about correcting the Helm source or release workflow so future installs, upgrades, and rollbacks stay healthy.

## Mistake 2: Skipping validation
After changing the chart, run lint, template, or the live Helm command path that proves the release matches the objective: helm template renders without error

## Mistake 3: Ignoring release history
Many Helm problems are easier to solve when you inspect `helm status`, `helm get`, or `helm history` first. If you skip that context, it is easy to solve the wrong problem.
