# Pod collector - shared chart, one release per team

Two teams run the same `collector` chart, each in its own namespace:

| team | release  | namespace            | values file          |
|------|----------|----------------------|----------------------|
| A    | `team-a` | `helmissions-team-a` | `values/team-a.yaml` |
| B    | `team-b` | `helmissions-team-b` | `values/team-b.yaml` |

The collector reads the cluster's pod list through the Kubernetes API with its own ServiceAccount; its status page
(`http://<release>-collector/status`, inside the release's namespace) reports `pods-api=200` when it is allowed to.

Team A has been running for weeks. Team B's rollout (`bash install-teams.sh`) was supposed to be a copy of A's.
