        # The First Deploy Walkthrough

        This level is primarily solved with Helm commands rather than by editing the chart files directly.

        1. Change into the sandbox chart directory: `cd sandbox/current`
2. Install the chart with a valid release name instead of a name that starts with a digit.
3. Use: `helm install nginx-app ./broken -n helmissions --create-namespace`
4. Verify with: `helm list -n helmissions` and `helm status nginx-app -n helmissions`
