# The Upgrade That Undid Itself — Walkthrough

1. The release is `deployed`, but which version? Read the history:
   ```bash
   helm history telemetry-gw -n helmissions
   # 1 superseded  Install complete
   # 2 failed      Upgrade "telemetry-gw" failed: ... CronJob ... spec.schedule: Invalid value: "every 15 minutes"
   # 3 deployed    Rollback to 1
   ```
   Revision 3 is the automatic rollback (`--rollback-on-failure` on Helm 4, `--atomic` on Helm 3).
2. Look at the CronJob the chart renders: `helm template telemetry-gw ./telemetry-gw`.
   `report.schedule` is `"every 15 minutes"`, which is not cron syntax.
3. Set `report.schedule: "*/15 * * * *"` in `telemetry-gw/values.yaml`.
4. Upgrade again (keeping the safety flag is a good idea):
   ```bash
   helm upgrade telemetry-gw ./telemetry-gw -n helmissions --rollback-on-failure   # Helm 3: --atomic
   ```
5. Verify revision 4 is `deployed` with description `Upgrade complete`; 3 pods Ready; `SAMPLE_RATE=0.25`.
