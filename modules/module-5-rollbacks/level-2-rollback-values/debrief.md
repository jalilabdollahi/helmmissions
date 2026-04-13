# Values Travel Back Too

## Situation
Player expects rollback to restore previous values — confirm this behavior. In this mission the broken state is intentional, and the point is not just to make Helm stop complaining. The real lesson is learning how Helm reports failure, where chart defects surface, and how release state and rendered manifests can drift apart when a deployment goes wrong.

## The Fix
Primary action: Rollback restores replicaCount to 3

A strong solution should leave both the chart and the cluster in a healthy state. In Helm that usually means checking the source of truth first, fixing the right file or release action, and then confirming that the next install, upgrade, rollback, or hook execution behaves the way you intended.

## What To Validate
Deployment has 3 replicas after rollback

Helpful checks for this level:
- `helm status helmissions-app -n helmissions`
- `helm history helmissions-app -n helmissions`
- `kubectl get all -n helmissions`

## Why It Matters
Review how the fix changed the Helm release for "Values Travel Back Too".

This matters in rollbacks & recovery work because Helm failures are rarely just syntax errors. In real teams they show up during CI/CD runs, emergency rollbacks, environment promotion, or cluster changes that expose assumptions hidden in a chart. If you only patch the symptom in-cluster, the same bug usually comes back on the next deployment.

A good operator learns the habit behind the fix: inspect the rendered output, understand the release history, and then make the smallest durable change that restores the expected behavior. That habit scales from a single broken values file all the way up to multi-service incident response.

## Concepts
values restored on rollback, what rollback restores
