# The Silent --set - Walkthrough

1. Look at what the release was given versus what the chart reads:
   ```bash
   helm get values billing -n helmissions     # USER-SUPPLIED VALUES: replicacount: 4
   grep -n replicaCount billing/values.yaml billing/templates/deployment.yaml
   ```
   The chart reads `replicaCount` (capital C). Values are case-sensitive and Helm never complains about
   keys that no template uses.
2. Upgrade with the right key. Do not use `--reuse-values`: it would keep the stray `replicacount`.
   ```bash
   helm upgrade billing ./billing -n helmissions --set replicaCount=4 --wait
   ```
3. Verify:
   ```bash
   helm get values billing -n helmissions      # replicaCount: 4 only
   kubectl get pods -n helmissions             # 4 workers
   ```
4. Run `check` in the game.
