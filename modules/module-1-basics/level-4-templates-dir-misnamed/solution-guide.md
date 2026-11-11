# The Empty Release - Walkthrough

1. Confirm the release exists but is empty:
   ```bash
   helm list -n helmissions                       # parcel-tracker, deployed
   helm get manifest parcel-tracker -n helmissions   # (empty)
   kubectl get all -n helmissions                 # No resources found
   ```
2. Look at the chart:
   ```bash
   ls parcel-tracker      # Chart.yaml  template  values.yaml
   ```
   The folder is `template`, singular. Helm only renders `templates/`.
3. Fix and roll out:
   ```bash
   mv parcel-tracker/template parcel-tracker/templates
   helm lint ./parcel-tracker
   helm upgrade parcel-tracker ./parcel-tracker -n helmissions --wait
   ```
4. Verify: `helm get manifest parcel-tracker -n helmissions | grep ^kind` and `kubectl get pods -n helmissions`.
5. Run `check` in the game.
