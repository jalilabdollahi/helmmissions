# Lint Before You Ship - Walkthrough

1. Run the CI gate and read all messages:
   ```bash
   ./ci/lint.sh
   # [ERROR]   Chart.yaml: appVersion should be of type string but it's of type float64
   # [ERROR]   Chart.yaml: invalid source URL 'github.com/helmissions-demo/newsletter'
   # [INFO]    Chart.yaml: icon is recommended               (ignorable)
   # [WARNING] Chart.yaml: version '1.0' is not a valid SemVerV2
   # [WARNING] templates/configmap.yaml: object name does not conform to Kubernetes naming requirements: "Newsletter-settings"
   # [WARNING] templates/service.yaml: object name does not conform ... "Newsletter"
   ```
2. Fix `newsletter/Chart.yaml`:
   - `appVersion: 2.3` is parsed as a float: quote it, `appVersion: "2.3"`.
   - `sources` entries must be URLs: `https://github.com/helmissions-demo/newsletter`.
   - `version: "1.0"` is not SemVer: use `1.0.0`.
   - `name: Newsletter` is used in object names (`{{ .Chart.Name }}`), which must be lowercase: `newsletter`.
3. Run `./ci/lint.sh` until it prints `0 chart(s) failed`.
4. Install the fixed chart:
   ```bash
   helm install newsletter ./newsletter -n helmissions --wait
   ```
5. Run `check` in the game.
