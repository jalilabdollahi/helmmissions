# Not A Library After All — Walkthrough

1. Reproduce and trace the ConfigMap:
   ```bash
   helm template receipt-mailer ./receipt-mailer | grep -B3 -A8 mq-defaults
   # Source: receipt-mailer/charts/mqlib/templates/mq-config.yaml
   helm get manifest invoice-mailer -n helmissions | grep -c mq-defaults    # invoice-mailer owns it
   ```
2. `helm show chart ./mqlib` shows no `type`, which means `application`. An application subchart renders
   every non-partial file in `templates/` — including the "demo defaults" ConfigMap with a fixed name, so two
   releases in one namespace collide.
3. Fix the chart:
   * `mqlib/Chart.yaml`: add `type: library`.
   * rename `templates/mq-config.yaml` to `templates/_mq-config.tpl` and delete the demo ConfigMap at the bottom.
     (A library only loads `_`-prefixed files; without the rename the `define`s would be ignored and the
     consumers would fail with `no template "mqlib.configmap" associated with template "gotpl"`.)
4. Refresh the packaged copies of mqlib in the consumers:
   ```bash
   helm dependency update ./invoice-mailer
   helm dependency update ./receipt-mailer
   ```
5. Roll out: upgrade `invoice-mailer` (this removes `mq-defaults` from its release) and then install
   `receipt-mailer` (a plain `helm install` works now; `helm upgrade --install` too).
6. Check `helm install x ./mqlib` now says `library charts are not installable`.
