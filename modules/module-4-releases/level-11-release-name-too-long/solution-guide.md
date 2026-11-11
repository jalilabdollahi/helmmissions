# Must Be No More Than 63 Characters — Walkthrough

1. Render with the real name:
   ```bash
   helm template customer-notification-dispatcher-production-eu ./notification-dispatcher | grep -E '^  name:'
   ```
   The Service is `customer-notification-dispatcher-production-eu-notification-dispatcher` (69 characters).
2. Edit `notification-dispatcher/templates/_helpers.tpl`: add `| trunc 63 | trimSuffix "-"` to the generated
   fullname (and to `fullnameOverride`).
3. Re-render and check every name is ≤ 63 characters.
4. The failed install left a failed release record, so upgrade it (or uninstall and install again):
   ```bash
   helm upgrade customer-notification-dispatcher-production-eu ./notification-dispatcher -n helmissions --wait
   ```
   (`helm list --failed -n helmissions` shows the record; uninstall + install works too.)
5. Run `check`.
