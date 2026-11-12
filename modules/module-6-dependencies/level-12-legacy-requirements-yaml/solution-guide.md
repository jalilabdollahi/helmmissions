# The Competing Dependency List — Walkthrough

1. Compare the declared and the effective dependency list:
   ```bash
   cd sandbox/current
   grep -n "name:" payroll/Chart.yaml          # tax-tables and pay-calendar are declared
   helm dependency list ./payroll              # ... only tax-tables is listed
   ls payroll                                  # requirements.yaml is still there
   ```
2. `requirements.yaml` is the Helm 2 location for dependencies. Helm still reads it for v2 charts and it overrides the
   list from `Chart.yaml`, with only an INFO message. Delete it (Chart.yaml is already complete):
   ```bash
   rm payroll/requirements.yaml
   ```
3. Re-resolve (this rewrites Chart.lock and charts/) and roll out:
   ```bash
   helm dependency update ./payroll
   helm dependency list ./payroll              # both ok
   helm upgrade payroll ./payroll -n helmissions --wait
   kubectl get deploy -n helmissions
   ```
4. Run `check`.
