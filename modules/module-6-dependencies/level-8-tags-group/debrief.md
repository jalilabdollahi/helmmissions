# Toggle A Group

## What broke
Three monitoring subcharts were meant to share the tag `monitoring`, and `tags.monitoring: false` was set in the
values. One dependency, `log-shipper`, was declared with the tag `monitorng` (typo). No value ever mentions that tag,
so Helm left the subchart enabled and it kept running while its two siblings were removed.

## Why Helm behaves this way
`tags:` on a dependency is a list of group labels; the parent's values control them under a top-level `tags:` map
(`tags.monitoring: false`). For each dependency Helm looks at its tags that are present in the values: if any is
true the subchart is enabled, if there is at least one and all of them are false it is disabled, and if none of its tags is
mentioned at all the dependency stays enabled. Absence means *on*, so a misspelled tag fails open.
A `condition:` on the same dependency, when its path exists, wins over tags. Tags only exist in the top-level
values of the chart that declares the dependency: they cannot be set from inside a subchart.

## The fix
Give all three dependencies the same tag (`monitoring`), refresh the lock because the declaration changed,
and upgrade. Then confirm both directions with `helm template`: no monitoring objects by default, all three with
`--set tags.monitoring=true`. Adding `monitorng: false` to the values would hide the symptom but break the group toggle.

## In real life
Tags are the right tool for "the observability bundle", "the dev tools bundle" or "the demo data" switches across many
subcharts, and are the usual way umbrella charts offer coarse feature groups per environment (a `values-dev.yaml`
that turns a bundle off). The failure mode is always the same: a tag typo or a forgotten tag on a newly added component
leaves one piece running in an environment where it should not (the same typo in a production values file leaves part of a bundle in the wrong state).

## Commands worth remembering
- `helm show chart ./chart` — dependencies with their tags and conditions
- `helm template r ./chart --set tags.<group>=true` — flip a group without editing files
- `helm get values <rel> --all` — the `tags` map as the release saw it
- `helm dependency update ./chart` — refresh the lock after changing declarations

## Common mistakes
- Hand-deleting the leftover Deployment: the release still owns it and the declaration is still wrong.
- Adding the typo'd tag to values.yaml: quiet in this environment, but `tags.monitoring=true` no longer brings the group back.
- Forgetting that an unmentioned tag means enabled.

## Helm 3 vs Helm 4
Same tag semantics and same fail-open behaviour in both versions.
