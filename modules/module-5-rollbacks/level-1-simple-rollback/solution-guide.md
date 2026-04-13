        # One Step Back Walkthrough

        This level is primarily solved with Helm commands rather than by editing the chart files directly.

        1. This level should be solved with a rollback command.
2. Inspect revisions: `helm history helmissions-app -n helmissions`
3. Rollback to the last known good revision: `helm rollback helmissions-app 1 -n helmissions`
4. Verify the workload and values are restored after the rollback completes.
