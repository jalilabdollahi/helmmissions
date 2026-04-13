        # Already Taken Walkthrough

        This level is primarily solved with Helm commands rather than by editing the chart files directly.

        1. The fix is to use an idempotent Helm command.
2. Run: `helm upgrade --install webapp ./broken -n helmissions`
3. This works whether the release already exists or not.
4. Verify with `helm list -n helmissions` and `helm history webapp -n helmissions`.
