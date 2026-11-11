# Name Rejected

## What broke
`deploy.sh` called `helm install Shop_Frontend ./storefront`. Before it renders anything or talks to the
cluster, Helm validates the release name and refused `Shop_Frontend`. The chart was never the problem -
the one argument the pipeline author typed by hand was.

## Why Helm behaves this way
Helm builds Kubernetes object names from the release name (`{{ .Release.Name }}` is in almost every
chart: Deployment, Service, ConfigMap...). Kubernetes requires those names to be DNS-1123 compliant:
lowercase letters, digits and `-` (plus `.` between labels), starting and ending with an alphanumeric.
Helm enforces the rule up front, plus a maximum length of 53 characters (so that suffixes added by
controllers, such as the pod hash, still fit in the 63 character limit of a DNS label). Failing early is
kinder than a half-created release.

## The fix
Rename the release in the script to a valid name (`shop-frontend`) and run the script again. Fixing the
file rather than typing the command by hand matters: the next pipeline run will use the script.

## In real life
Names often come from branch names, ticket IDs or Jira keys (`Feature_PROJ-123`) and are fed to
`helm install` by CI. Sanitise them in the pipeline (`tr '[:upper:]_' '[:lower:]-'`, truncate to 53)
instead of discovering the rule at 5pm on a Friday. Treat the release name as an identifier other tools
depend on (dashboards, alerts, `helm list` filters) and change it deliberately.

## Commands worth remembering
- `helm install <name> <chart> -n <ns>` - the name is the first positional argument
- `helm install <chart> --generate-name` - let Helm pick a valid name for throwaway installs
- `helm upgrade --install <name> <chart>` - idempotent form that CI pipelines prefer
- `helm list -n <ns>` - confirm the release exists and under which name

## Common mistakes
- Fixing the name only in a hand-typed command: the script in the repo is still broken.
- Replacing `_` with nothing (`ShopFrontend` is still invalid - uppercase is rejected too).
- Choosing a name longer than 53 characters; it fails later with a different error.

## Helm 3 vs Helm 4
Both enforce the same regex and length. The wording differs slightly: Helm 4 reports "release name check
failed" and also logs a structured `level=ERROR` line before the final `Error:` line. The "still in use"
message is spelled "cannot reuse a name" in Helm 4 and "cannot re-use a name" in Helm 3.
