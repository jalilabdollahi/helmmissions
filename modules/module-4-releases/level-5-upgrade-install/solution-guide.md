        # One Command Rules All Walkthrough

        This level is primarily solved with Helm commands rather than by editing the chart files directly.

        1. This level is about making the deployment command idempotent.
2. Run: `helm upgrade --install myapp ./broken -n helmissions --create-namespace`
3. Run it a second time to confirm the same command works for upgrades too.
4. Verify with `helm status myapp -n helmissions` and `helm history myapp -n helmissions`.
