# HelmMissions ⛵⚔️

![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20-blue)
![shell](https://img.shields.io/badge/shell-bash-brightgreen)
![helm](https://img.shields.io/badge/helm-3.14%2B%20%7C%204.x-0f1689)

> **Learn Helm by breaking it, then fixing it.**

HelmMissions is a fully local, game-based Helm troubleshooting platform with a rich terminal interface.
Each mission drops a deliberately broken chart, release, or upgrade path in front of you. Your job is to
diagnose and fix it using real `helm` and `kubectl` commands against a local kind cluster.

**133 hand-crafted missions across 10 modules — from your first install to production war games.**
Every mission breaks something different. No cloud. No costs.

---

## ✨ Features

- ⛵ **133 unique missions** — each one a different real-world Helm failure
- 🧪 **Behaviour-based validation** — any correct fix passes; hotfixes that Helm would undo don't
- 💡 **Progressive hints** and a full walkthrough when you're stuck
- 📖 **Debriefs** — why Helm behaves that way, how it bites teams in production, commands to remember
- 👁️ **Watch mode** — re-validates every 5 seconds until you pass
- 🏅 **Module certificates** — earned only when every level of a module is solved (skips don't count)
- 🔒 **Safety guards** — the game only ever touches the `kind-helmissions` cluster
- 🧭 **Helm 4 ready** — written and tested on Helm 4, compatible with Helm 3.14+; debriefs call out the differences

---

## 🚀 Quick Start

```bash
cd helmissions
./install.sh     # checks tools, creates the venv, the kind cluster and a local OCI registry
./play.sh
```

## 📋 Prerequisites

| Tool | Install |
|------|---------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | *(must be running)* |
| [kind](https://kind.sigs.k8s.io/) | `brew install kind` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `brew install kubectl` |
| [Helm 3.14+ or 4.x](https://helm.sh/docs/intro/install/) | `brew install helm` |
| Python **3.9+** | `brew install python` |
| [jq](https://jqlang.github.io/jq/) | `brew install jq` |
| gpg *(only for the chart-signing mission)* | `brew install gnupg` |

`install.sh` creates:
- kind cluster **`helmissions`** (context `kind-helmissions`)
- a local OCI registry at **`localhost:5001`** (also pullable from inside the cluster)
- a local classic chart repository at **`http://localhost:8879`**

---

## 🎮 How to Play

1. **Run** `./play.sh` — keep this terminal open for the game
2. **Open a second terminal** in `sandbox/current/` — that's your workspace for the active level
3. **Read the briefing** — the situation (symptoms and error text) and the objective (what must be true)
4. **Investigate and fix** with `helm` and `kubectl` — edit files in the workspace, run upgrades, rollbacks…
5. **Validate** with `check` (or `1`) and earn XP

The workspace is rebuilt for every level and on `reset`. The game refuses to run if your current kubectl
context isn't `kind-helmissions`, because resetting a level deletes namespaces.

## 🎯 Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `check` | `1` | Validate your solution |
| `check-dry` | `d` | Run the validator without awarding XP |
| `watch` | `w` | Auto-validate every 5 seconds until pass |
| `hint` | `2` | Reveal the next of 3 progressive hints |
| `guide` | `3` | Full walkthrough + reference files |
| `debrief` | `4` | Re-read the lesson for the current level |
| `helm <args>` | `5 <args>` | Run Helm (from the workspace) through the safety guard |
| `kubectl <args>` | `5k <args>` | Run kubectl through the safety guard |
| `edit <kind> <name>` | `e` | Edit a live object in `$EDITOR` |
| `reset` | `6` | Rebuild the current level from scratch |
| `status` | `7` | Module progress and XP |
| `skip` | `8` | Skip the level (no XP, no certificate) |
| `goto <M>.<L>` | | Jump to any level, e.g. `goto 5.3` |
| `briefing` | | Show the mission briefing again |
| `quit` | `9` | Save and exit |
| `reset-progress` | `0` | Wipe all progress |

---

## 🗺️ Learning Path

| # | Module | Levels | Difficulty | Key Topics |
|---|--------|--------|------------|------------|
| 1 | 🟢 Helm Basics | 15 | Beginner | Chart metadata, installs, upgrades, get/show, lint, package |
| 2 | 🟢 Values & Overrides | 15 | Beginner → Intermediate | Types, `--set` syntax, `--set-file`, file order, schema, `--reuse-values` |
| 3 | 🟡 Template Debugging | 20 | Intermediate → Advanced | Go templates, context, whitespace, helpers, `tpl`, `lookup`, Capabilities |
| 4 | 🟡 Release Management | 15 | Intermediate → Advanced | Release states, ownership, immutable fields, stuck releases, CRDs, tests |
| 5 | 🟡 Rollbacks & Recovery | 15 | Intermediate → Advanced | History, drift, pruning, storage drivers, forced replacement, incidents |
| 6 | 🔴 Chart Dependencies | 13 | Advanced | Locks, version ranges, aliases, globals, conditions, tags, OCI, import-values |
| 7 | 🔴 Helm Hooks | 10 | Advanced | Phases, weights, delete policies, test hooks, hook RBAC |
| 8 | 🔴 Security & Linting | 10 | Advanced | Secrets, RBAC, NetworkPolicy, PSA, quotas, removed APIs, provenance |
| 9 | ⚫ Advanced Patterns | 10 | Expert | Library charts, OCI, post-renderers, plugins, kustomize, repo indexes |
| 10 | ⚫ Production War Games | 10 | Expert | Multi-failure incidents across releases and namespaces |

---

## 📁 Project Structure

```text
helmissions/
├── play.sh / install.sh
├── engine/
│   ├── engine.py          ← game loop and commands
│   ├── reset.py           ← cluster cleanup, workspace refresh, running level scripts
│   ├── safety.py          ← helm/kubectl guards
│   ├── ui.py, certificate.py, player.py
│   └── lib/common.sh      ← bash helpers for level scripts
├── scripts/
│   ├── cluster.sh         ← kind cluster + local registry / chart repo
│   ├── test_levels.py     ← end-to-end level tester
│   ├── agent_env.sh       ← isolated cluster/helm env for parallel level authoring
│   └── generate_registry.py ← writes levels.json (index of all missions)
├── docs/
│   ├── LEVEL_SPEC.md      ← how a level is built
│   └── CURRICULUM.md      ← what every level teaches and breaks
└── modules/module-N-*/level-N-*/
    ├── mission.yaml       ← briefing
    ├── broken/            ← starting workspace (copied to sandbox/current/)
    ├── solution/          ← fixed workspace (shown by `guide`)
    ├── setup.sh validate.sh solve.sh tests/
    ├── hint-1..3.txt  solution-guide.md  debrief.md
```

## 🛠️ Authoring & testing levels

Read [docs/LEVEL_SPEC.md](docs/LEVEL_SPEC.md). Every level ships a reference `solve.sh` and tests for
tempting wrong fixes, and the harness proves the validator fails on the broken state, passes after the
reference fix, and rejects the wrong ones:

```bash
export KUBECONFIG=$PWD/.hm-shared/main/kubeconfig   # optional: don't touch your global context
kind get kubeconfig --name helmissions > "$KUBECONFIG"
venv/bin/python scripts/test_levels.py --module module-3-templates
venv/bin/python scripts/test_levels.py --all
```

## 🔄 Resetting Progress

`./play.sh --reset` or `reset-progress` in the game. `reset` rebuilds only the current level.

## 📄 License

MIT License.
