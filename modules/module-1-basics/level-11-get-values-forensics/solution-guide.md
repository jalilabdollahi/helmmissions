# The Mystery Override - Walkthrough

1. The chart is fine, so look at the release's inputs:
   ```bash
   helm get values weather-widget -n helmissions
   # USER-SUPPLIED VALUES:
   # config:
   #   apiUrl: http://localhost:9999
   ```
2. Compare with the chart default: `grep apiUrl weather-widget/values.yaml`.
3. Redeploy the chart and make Helm forget the stored override. A plain `helm upgrade` is NOT enough:
   when you pass no new values, Helm carries the previous user values over (try it: the override stays).
   ```bash
   helm upgrade weather-widget ./weather-widget -n helmissions --reset-values --wait
   helm get values weather-widget -n helmissions     # USER-SUPPLIED VALUES: null
   ```
4. Check the ConfigMap: `kubectl get cm weather-widget-config -n helmissions -o jsonpath='{.data.config\.json}'`.
5. Run `check` in the game.
