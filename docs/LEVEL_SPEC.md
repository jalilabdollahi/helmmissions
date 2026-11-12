# HelmMissions Level Specification

Every level is hand-authored. There is no generator. A level is a directory
`modules/module-<M>-<name>/level-<N>-<slug>/` and is the single source of truth for that mission.
The curriculum (what each level teaches and breaks) lives in [CURRICULUM.md](CURRICULUM.md).

## 1. Directory layout

```
level-N-slug/
  mission.yaml          briefing metadata (required)
  broken/               the player's starting workspace — copied to $SANDBOX on every reset (optional
                        for pure command levels, but most levels have one)
  solution/             the same workspace AFTER a correct fix (full copy, not a diff). Shown by `guide`.
                        Omit only for levels that are solved purely with commands.
  assets/               private files used by setup.sh / solve.sh (good chart revisions, repo content,
                        keyrings…). The player never needs to open these.
  setup.sh              builds the broken scenario (required)
  validate.sh           decides pass/fail (required)
  solve.sh              reference solution, executed only by the test harness (required)
  tests/                optional extra scripts for the harness:
     alt-*.sh             an alternative CORRECT fix → validate.sh must pass afterwards
     fail-*.sh            a plausible WRONG / partial fix → validate.sh must still fail afterwards
  hint-1.txt hint-2.txt hint-3.txt
  solution-guide.md     step-by-step walkthrough (required)
  debrief.md            the lesson shown after passing (required)
```

`broken/` contents are copied to the root of the workspace. Put the chart in a named folder,
e.g. `broken/webapp/Chart.yaml` → `$SANDBOX/webapp/Chart.yaml`. Extra files (values files,
CI scripts, a `deploy.sh`, a `README.txt` with context) can sit next to it.

## 2. mission.yaml

```yaml
name: "Ghost Deployment"                 # short, evocative title
description: |                           # SITUATION: what the operator observes — symptoms and the exact
  The `catalog` release installs cleanly  # error text if there is one. 2-5 sentences. NEVER the fix.
  but `kubectl get pods` shows nothing...
objective: |                             # SUCCESS CRITERIA in observable terms (what must be true),
  Release `catalog` in namespace           # including release names / namespaces / values the validator
  `helmissions` runs 2 ready pods ...      # checks. Don't describe how to fix it.
xp: 150
difficulty: beginner                     # beginner | intermediate | advanced | expert
expected_time: 10m
concepts: [chart structure, templates directory]
```

## 3. Script contract

All scripts are run by the engine with `bash <script>`, **cwd = `$SANDBOX`**, and this environment:

| Var | Meaning |
|-----|---------|
| `NS` | primary namespace, always `helmissions` |
| `LEVEL_DIR` | absolute path of the level directory |
| `SANDBOX` | absolute path of the player workspace |
| `HM_LIB` | helper library — every script must `source "$HM_LIB"` |
| `HM_PYTHON` | python3 with PyYAML |
| `HM_REGISTRY` | shared OCI registry `localhost:5001` (no auth, also pullable by the cluster as `localhost:5001/...`) |
| `HM_CHARTREPO_DIR` / `HM_CHARTREPO_URL` | a directory served as `http://localhost:8879` for classic chart repos |

Start every script with:

```bash
#!/bin/bash
set -euo pipefail        # validate.sh: use `set -uo pipefail` and handle failures with hm_fail
source "$HM_LIB"
```

Read [engine/lib/common.sh](../engine/lib/common.sh) — it has `hm_fail`, `hm_ok`, `hm_info`,
`hm_pass`, `hm_require_deployed`, `hm_release_status`, `hm_history_json`, `hm_user_values`,
`hm_all_values`, `hm_wait_rollout`, `hm_endpoints_count`, `hm_http_check`, `hm_yaml_get`,
`hm_render_json`, `hm_manifest_json`, `hm_chartrepo_path`, `hm_registry_up`, `hm_helm_major`, and an
auto-cleaned temp dir `$HM_TMP`. The library installs an EXIT trap; if you need your own trap, chain it.
Never pin a kube context in scripts (no `--kube-context`, no `kind-helmissions`).

Before `setup.sh` runs, the engine has already: deleted every `helmissions` / `helmissions-*`
namespace (so all releases are gone), deleted cluster-scoped objects labelled
`helmissions.io/cleanup=true`, removed Helm repos and plugins whose names start with `hm-`,
recreated namespace `helmissions`, and copied `broken/` into `$SANDBOX`.

### setup.sh
* Builds the scenario: installs releases (from `$SANDBOX/...` when the player's files ARE the deployed
  thing, from `$LEVEL_DIR/assets/...` for hidden earlier revisions), creates conflicting objects,
  simulates a colleague's bad command, etc.
* Commands that are *supposed* to fail get `|| true`; then **assert** the intended broken state was
  reached (e.g. `[ "$(hm_release_status web)" = failed ] || { echo "setup did not reach failed state"; exit 1; }`).
* Must be deterministic, re-runnable, and finish in < 3 minutes. Use `--wait`/`--timeout` deliberately.

### validate.sh
* **Behaviour-based.** Check what must be true (release state, live objects, rendered output, files in
  the workspace that are the source of truth). Never `diff` against `solution/` — any correct fix must pass.
* **Rejects partial fixes.** E.g. if the lesson is "fix the chart", a `kubectl edit` hotfix must fail;
  if the lesson is "upgrade the release", a fixed file that was never deployed must fail.
* Prints a short line per check (`hm_info` / `hm_ok`), and on failure a message that names the *symptom*
  (`❌ Service catalog has 0 ready endpoints`), not the answer. Exit 0 = pass.
* Fast (< 90 s) and **read-only** where possible. If it must mutate (e.g. prove an upgrade is now
  idempotent, or run `helm test`), keep it scoped (use namespace `helmissions-verify` for throwaway
  installs and clean it up).
* Must fail right after setup (the harness checks this).

### solve.sh
The reference solution, executed by the harness on top of a fresh setup. Do exactly what a player
would do (edit workspace files — usually `cp -R "$LEVEL_DIR/solution/." "$SANDBOX/"` — then run the
helm/kubectl commands). It must make validate.sh pass.

### tests/
Add at least one `tests/fail-*.sh` per level that performs the most tempting wrong fix (kubectl hotfix
instead of chart fix, fixing the file but not upgrading, uninstalling instead of upgrading when history
matters, editing the schema instead of the values…). Add `tests/alt-*.sh` when there are several valid
fixes (e.g. `upgrade` vs `uninstall+install`, `--take-ownership` vs annotating). Same env / cwd as solve.sh.

## 4. Cluster & environment rules

* Namespaces: only `helmissions` and `helmissions-<something>`. Nothing in `default`.
* Cluster-scoped objects (CRDs, ClusterRoles, …) must carry label `helmissions.io/cleanup: "true"`
  and a name containing `helmissions` (e.g. CRD group `*.helmissions.io`).
* Helm repos / plugins that a level adds must be named `hm-*`.
* OCI artifacts: push under `localhost:5001/<module-short>-<level-slug>/...` so levels never collide.
  Classic repos: `hm_chartrepo_path <module-short>-<level-slug>` → served at `$HM_CHARTREPO_URL/<same>`.
* Extra docker containers only if unavoidable; name them `helmissions-<slug>`, put them on the `kind`
  network, and make setup remove+recreate them. Port 5002 is reserved for `helmissions-private`
  (the cluster's containerd already maps `localhost:5002` → `http://helmissions-private:5000`).
* Images (preloaded into the cluster, always use these exact tags, `imagePullPolicy: IfNotPresent`):
  `nginx:1.27-alpine`, `nginxinc/nginx-unprivileged:1.27-alpine` (uid 101, port 8080),
  `busybox:1.36`, `curlimages/curl:8.10.1`, `traefik/whoami:v1.10`.
  A deliberately broken tag (typo) is fine for ImagePullBackOff scenarios.
* Keep pods small: requests ≤ 50m CPU / 64Mi, set `terminationGracePeriodSeconds: 2` where you can
  (resets get faster). Default replicas 1–2.
* Tools available to players: helm, kubectl (incl. `kubectl kustomize`), jq, docker, python3, gpg.
  Do NOT require helmfile, kustomize binary, cosign, ArgoCD, operators, or internet access other than
  the preloaded images.
* Helm: primary target is **Helm 4.x** (installed: v4.3). Stay compatible with Helm 3.14+ where a neutral
  option exists. Where flags differ (`--atomic` ↔ `--rollback-on-failure`, `--force` ↔ `--force-replace`,
  post-renderer executables ↔ plugins), solve.sh branches on `hm_helm_major` and the debrief explains both.
  Helm 4 uses server-side apply by default for new releases (`--server-side auto`) — keep it in mind.
* **Verify every premise on the real Helm 4 before building a level.** Helm 4 differs from Helm 3 in
  places the curriculum may not anticipate. Known so far:
  - a Chart.yaml without `apiVersion` installs fine on Helm 4 (lint still errors) — missing `name` or
    `version` still blocks installs;
  - `helm status -o json` has no `.chart` — use `hm_release_chart` / `helm history -o json`;
  - `helm list` has no `-a/--all` flag (use `--deployed --failed --pending ...` or `helm history`);
  If a curriculum premise is false on Helm 4, adapt the scenario minimally so the same lesson holds
  on Helm 4 (and ideally Helm 3), keep it distinct from every other level, and note the change in the
  debrief's `## Helm 3 vs Helm 4` section.

## 5. Writing quality

* **Every level is unique.** Different app/release names, different domain (shop, payments, search,
  telemetry, ledger…), a different chart shape. Do not clone one base chart across levels; keep charts
  small and realistic (only the templates the story needs). The broken thing must be exactly what the
  curriculum entry says, and nothing else may be broken by accident.
* **Realistic.** Errors are the real Helm/Kubernetes errors. The player discovers the problem with real
  commands (`helm status`, `helm history`, `helm get values|manifest|notes`, `helm template --debug`,
  `helm lint`, `kubectl describe`, `kubectl get events`, `kubectl logs`).
* hint-1: where to look (a diagnostic command). hint-2: what is wrong. hint-3: almost the fix.
  2–6 lines each, plain text.
* solution-guide.md: numbered walkthrough with the exact commands, what the output shows, the edit, and
  how to verify.
* debrief.md (≥ 800 chars) with these sections:
  `## What broke` · `## Why Helm behaves this way` · `## The fix` · `## In real life`
  (where this bites teams in CI/CD and production) · `## Commands worth remembering` ·
  `## Common mistakes` (2–3 bullets) · and, when relevant, `## Helm 3 vs Helm 4`.

## 6. Testing

```bash
source scripts/agent_env.sh <slot>         # isolated cluster/helm/sandbox per author (slot 1..4)
venv/bin/python scripts/test_levels.py -v modules/module-1-basics/level-1-...   # one level
venv/bin/python scripts/test_levels.py --module module-1-basics                 # whole module
```

Shell state does not persist between tool calls, so prefix every command with the `source` line.
A level is done only when the harness prints `[PASS]` for it.
