Ledger platform label standard (every workload object and every pod template):

  app.kubernetes.io/name         chart name
  app.kubernetes.io/instance     release name
  app.kubernetes.io/version      appVersion of the chart
  app.kubernetes.io/part-of      ledger          (always this literal value)
  app.kubernetes.io/managed-by   Helm            (.Release.Service)
  helm.sh/chart                  <chart>-<chart version>

Pod selectors stay name + instance only (selectors are immutable on a live Deployment).
The platform team wants ONE definition of this, not one per chart.
