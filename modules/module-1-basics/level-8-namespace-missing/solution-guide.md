        # Where Am I? Walkthrough

        This level is primarily solved with Helm commands rather than by editing the chart files directly.

        1. This level is about the install command, not editing chart files.
2. Install with namespace creation enabled: `helm install helmissions-app ./broken -n helmissions-extra --create-namespace`
3. If you prefer, create the namespace first with kubectl and then install without `--create-namespace`.
4. Verify the release exists in the target namespace with `helm list -n helmissions-extra`.
