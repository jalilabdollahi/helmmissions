# Plugin Won't Load

## What broke
`plugin.yaml` told Helm to run two programs — the command behind `helm hm-audit` and an install hook — from paths
that do not exist in the plugin directory (`bin/` and `hooks/` instead of `scripts/`). Helm reported a raw
`fork/exec ...: no such file or directory`, and because the hook fails after the plugin directory has been put in
place, a half-installed plugin stayed behind. It was listed, but neither the hook-generated `rules.env` nor the command worked.

## Why Helm behaves this way
A Helm plugin is a directory with a `plugin.yaml` and whatever it executes. In Helm 4, `apiVersion: v1` plugins declare
a `type` (`cli/v1` for subcommands, `postrenderer/v1`, `getter/v1`), a `runtime` (`subprocess`) and per-platform commands under
`runtimeConfig.platformCommand`, plus optional `platformHooks` (`install`, `update`, `delete`). Helm does not search for the
program: it expands `${HELM_PLUGIN_DIR}` and executes exactly that path, so a wrong path is an exec error, not a "plugin
invalid" message. Hooks run once, at the moment of `helm plugin install/update`; fixing `plugin.yaml` afterwards does not
re-run them. The first word of `config.usage` is the subcommand name users type. Local directories install in "development
mode" (a symlink to your source), so edits to scripts apply immediately, while tarballs are verified against a `.prov`
signature unless you pass `--verify=false`.

## The fix
Correct the paths (or move the scripts), then uninstall and reinstall so the hook runs. Verify on a clean machine or an
isolated `HELM_PLUGINS` directory: it is easy to "fix" a plugin that only works because of files left from an earlier attempt.

## In real life
Plugins are how teams ship internal tooling next to Helm: `helm diff`, `helm secrets`, `helm-unittest`, compliance and
audit checks. Typical failures are paths valid only on the author's laptop, missing exec bits, binaries downloaded by an
install hook for the wrong OS/architecture, and CI images that never ran the install hook. Pin plugin versions
(`helm plugin install URL --version X`) in CI, install them in the image build, and test installation on every platform you support.

## Commands worth remembering
- `helm plugin list` — name, version, type, apiVersion, provenance
- `helm plugin install ./dir` / `helm plugin uninstall NAME` / `helm plugin update NAME`
- `helm plugin package ./dir` and `helm plugin verify` — signed plugin archives
- `echo $HELM_PLUGINS` / `helm env HELM_PLUGINS` — where plugins live

## Common mistakes
- Fixing plugin.yaml but not reinstalling: install hooks do not re-run, so generated files never appear.
- Running the script directly "to check": it bypasses the HELM_* environment Helm provides to plugins.
- Forgetting `chmod +x` on scripts; the error is `permission denied` from fork/exec.

## Helm 3 vs Helm 4
Helm 3 plugin.yaml is flat: `name`, `version`, `usage`, `description`, `command: "$HELM_PLUGIN_DIR/bin/audit.sh"` and
`hooks: {install: ...}`. Helm 4 still loads that legacy format (shown as apiVersion `legacy` in `helm plugin list`) but new plugins
use `apiVersion: v1` with `type`, `runtime`, `config` and `runtimeConfig`, as here. A plugin that fails to load at install time
is reported as "installed but unusable", and a failing install hook leaves the plugin installed.
