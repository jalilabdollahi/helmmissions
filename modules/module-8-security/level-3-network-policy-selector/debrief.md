# Policy Blocks The Frontend

## What broke
The chart ships a default-deny ingress policy plus one "allow" policy for the catalog backend. The allow
rule's `from.podSelector` asked for pods labelled `app.kubernetes.io/component: web`, but the frontend pods
are labelled `frontend`. No source matched, so the default-deny won and every connection from the frontend
timed out. The frontend's readiness probe (which exercises that path) never passed.

## Why Helm behaves this way
Helm renders and applies objects; it never checks whether a selector in one object matches the labels
in another. NetworkPolicies are additive allow-lists layered on a deny: a connection is permitted only if some
policy selects the destination pod AND lists the source in `from`. Selectors are exact label matches, and a typo
produces a perfectly valid object that simply matches nothing. NetworkPolicies are enforced by the CNI (kindnet
here enforces them), not by Kubernetes itself, so a cluster with a non-enforcing CNI would silently ignore them.

## The fix
Make the policy's source selector and the frontend pod labels agree — edit the selector (or relabel the pods),
then `helm upgrade`. Keep the default-deny and keep the selector narrow.

## In real life
Label drift is the classic cause: someone renames `app: web` to `app.kubernetes.io/component: frontend` in the
Deployment during a chart refactor and the policy, defined in a different file or even a different chart, keeps
the old label. The failure looks like an application timeout, so teams burn hours on DNS and Services. The
tempting "fix" under pressure is deleting the policy or widening the rule to `podSelector: {}` or an entire
namespace — the outage ends, and the isolation that the security review demanded disappears silently.
Test policies from both sides in CI: one pod that must connect and one that must not.

## Commands worth remembering
- `kubectl describe networkpolicy NAME` — shows which pods it selects and the allowed sources
- `kubectl get pods --show-labels` / `kubectl get pods -l key=value` — verify a selector matches what you expect
- `kubectl run probe --rm -it --image=curlimages/curl:8.10.1 -- curl -m 4 http://svc` — quick connectivity test
- `helm template . | grep -A20 'kind: NetworkPolicy'`

## Common mistakes
- Deleting the NetworkPolicy "to test" and leaving it deleted.
- Using `podSelector: {}` in `from` — it admits every pod in the namespace.
- Assuming a timeout means the Service is broken: check endpoints first, then policies.
- Forgetting that `namespaceSelector` and `podSelector` in the same `from` item are ANDed, in separate items ORed.

## Kubernetes note
kindnet in the game's kind cluster (Kubernetes 1.37) does enforce NetworkPolicy, so the blocked connection is real. Not every
local CNI does (the default kind CNI used to be a no-op for policies), which is why policy tests must always include a
"must be blocked" probe, as the validator here does.
