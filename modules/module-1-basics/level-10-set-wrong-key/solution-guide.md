        # Override Miss Walkthrough

        This level is primarily solved with Helm commands rather than by editing the chart files directly.

        1. The chart key is camelCase, so the override must match exactly.
2. Run an upgrade with the corrected key: `helm upgrade --install helmissions-app ./broken -n helmissions --set replicaCount=5`
3. Avoid `replicacount` or other case variants.
4. Verify with `helm get values helmissions-app -n helmissions --all`.
