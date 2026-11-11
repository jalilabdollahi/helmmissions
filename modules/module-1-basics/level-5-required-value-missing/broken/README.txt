docs-site - deployment notes
============================
The chart in ./docs-site is shared by all environments, so its defaults stay generic.
Environment-specific settings live in values files next to the chart.

Staging
  release name : docs-site
  namespace    : helmissions
  public host  : docs.staging.helmissions.local
