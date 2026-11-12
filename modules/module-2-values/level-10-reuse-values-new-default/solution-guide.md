# --reuse-values Ate My Default - Walkthrough

1. Reproduce the CI failure:
   ```bash
   bash ci-upgrade.sh
   # nil pointer evaluating interface {}.port
   ```
2. Compare values:
   ```bash
   helm get values notifier -n helmissions --all    # chart 1.0.0 defaults + replicaCount: 2, no "metrics"
   helm show values ./notifier                      # new chart: metrics.port: 9102
   ```
   `--reuse-values` freezes the old computed values; 2.0.0's new default is never merged in.
3. Use `--reset-then-reuse-values`: reset to the NEW chart's defaults, then re-apply the values the user
   supplied earlier:
   ```bash
   helm upgrade notifier ./notifier -n helmissions --reset-then-reuse-values --set image.tag=1.36
   ```
   (A plain `helm upgrade --set image.tag=1.36 --set replicaCount=2` also works but forces you to remember every override.)
4. Verify:
   ```bash
   helm list -n helmissions                # chart notifier-2.0.0
   helm get values notifier -n helmissions # replicaCount: 2
   kubectl get deploy notifier -n helmissions
   ```
5. Run `check`. Update the CI job to use the new flag too.
