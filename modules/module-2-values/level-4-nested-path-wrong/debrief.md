# Lost in the Tree

## Situation
Override is passed but has no effect — wrong nesting path. In this mission the broken state is intentional, and the point is not just to make Helm stop complaining. The real lesson is learning how Helm reports failure, where chart defects surface, and how release state and rendered manifests can drift apart when a deployment goes wrong.

## The Fix
Primary action: Change --set to `--set database.host=db` (remove extra `config.` prefix)

A strong solution should leave both the chart and the cluster in a healthy state. In Helm that usually means checking the source of truth first, fixing the right file or release action, and then confirming that the next install, upgrade, rollback, or hook execution behaves the way you intended.

## What To Validate
Correct value rendered in ConfigMap

Helpful checks for this level:
- `helm status helmissions-app -n helmissions`
- `helm lint ./broken`
- `kubectl get all -n helmissions`

## Why It Matters
Review how the fix changed the Helm release for "Lost in the Tree".

This matters in values & overrides work because Helm failures are rarely just syntax errors. In real teams they show up during CI/CD runs, emergency rollbacks, environment promotion, or cluster changes that expose assumptions hidden in a chart. If you only patch the symptom in-cluster, the same bug usually comes back on the next deployment.

A good operator learns the habit behind the fix: inspect the rendered output, understand the release history, and then make the smallest durable change that restores the expected behavior. That habit scales from a single broken values file all the way up to multi-service incident response.

## Concepts
nested values, --set path syntax, dot notation
