# Quota Says No — Walkthrough

1. `kubectl get deploy,rs,pods -n helmissions` — the Deployment has 0/2, no pods exist.
2. `kubectl describe rs -n helmissions` (or `kubectl get events`) shows
   `failed quota: search-team-quota: must specify limits.cpu ... requests.memory for: indexer`.
3. `kubectl describe resourcequota search-team-quota -n helmissions` lists the hard limits and current usage.
4. In `search-indexer/values.yaml` replace `resources: {}` with requests and limits that let two pods fit:
   ```yaml
   resources:
     requests: {cpu: 50m, memory: 64Mi}
     limits:   {cpu: 100m, memory: 128Mi}
   ```
5. `helm upgrade search-indexer ./search-indexer -n helmissions --wait`; the ReplicaSet creates the pods.
6. Verify with `kubectl describe resourcequota` (usage now non-zero) and run `check`.
