        # Gone But Not Forgotten Walkthrough

        This level is primarily solved with Helm commands rather than by editing the chart files directly.

        1. This level is about restoring a release from kept history.
2. Inspect history first: `helm history helmissions-app -n helmissions`
3. Restore the release with `helm rollback helmissions-app <revision> -n helmissions`
4. Verify the release returns to `deployed` state with `helm status helmissions-app -n helmissions`.
