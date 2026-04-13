# HelmMissions ⛵⚔️

![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20-blue)
![shell](https://img.shields.io/badge/shell-bash-brightgreen)
![helm](https://img.shields.io/badge/helm-learning-0f1689)

> **Learn Helm by breaking it, then fixing it.**

HelmMissions is a fully local, game-based Helm troubleshooting platform with a rich terminal interface. Each mission drops a deliberately broken chart, release, or upgrade path in front of you. Your job is to diagnose and fix it using real `helm` and `kubectl` commands.

**133 progressive challenges across 10 modules — beginner to production war games.**  
No cloud. No AWS. No costs.

---

## ✨ Features

- ⛵ **133 missions** across 10 modules — from first installs to rollback incidents
- 🏆 **XP & progression system** — earn points, track completions, move through modules
- 💡 **Progressive hints** — reveal only as much help as you need
- 📖 **Post-mission debriefs** — learn why the fix worked and what it means in practice
- 🧪 **Dry-run validation** — test your fix before committing XP
- 👁️ **Watch mode** — auto-runs validators until your level passes
- 🏅 **Module certificates** — complete a module and earn a terminal certificate
- 🔒 **Safety guards** — risky `kubectl` and local-state-changing Helm commands are gated
- 💾 **Auto-save** — progress is stored in `progress.json`
- 🛠️ **Generated content pipeline** — rebuild all levels directly from `PLAN.md`

---

## 🚀 Quick Start

```bash
cd helmissions
python3 scripts/build_levels.py
./install.sh
./play.sh
```

> Want to regenerate only the registry?
> ```bash
> python3 scripts/generate_registry.py
> ```

---

## 📋 Prerequisites

| Tool | Install |
|------|---------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | *(must be running)* |
| [kind](https://kind.sigs.k8s.io/) | `brew install kind` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `brew install kubectl` |
| [Helm 3+](https://helm.sh/docs/intro/install/) | `brew install helm` |
| Python **3.9+** | `brew install python@3.11` |
| [jq](https://jqlang.github.io/jq/) | `brew install jq` |

---

## 🎮 How to Play

1. **Run** `./play.sh` — the game loop runs here, keep this terminal open
2. **Open a second terminal** — use `helm` and `kubectl` to investigate the scenario
3. **Read the mission briefing** — understand what is broken and what success looks like
4. **Fix it** — repair the chart, release state, values, or workflow for the level
5. **Validate** — run `check` (or press `1`) to test your solution
6. **Earn XP** and move to the next mission

---

## 🎯 Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `check` | `1` | Validate your solution |
| `check-dry` | `d` | Dry-run validator without awarding XP |
| `watch` | `w` | Auto-validate every 5 seconds until pass |
| `hint` | `2` | Reveal the next progressive hint |
| `guide` | `3` | Show the reference `solution/` files |
| `debrief` | `4` | Re-read the lesson for the current level |
| `helm <cmd>` | `5` | Run Helm commands through HelmMissions safety |
| `kubectl <cmd>` | `5k` | Run kubectl verification commands safely |
| `reset` | `6` | Reset the current level back to broken state |
| `status` | `7` | Show current module progress and XP |
| `skip` | `8` | Skip the level with no XP awarded |
| `quit` | `9` | Save and exit |
| `reset-progress` | `0` | Wipe all XP and restart from level 1 |

---

## 🛡️ Safety First

HelmMissions includes built-in command safety guards:

- 🔐 The game is built around the `helmissions` namespace
- 🚫 Destructive `kubectl` operations against critical namespaces are blocked
- ⚠️ Risky Helm commands like `helm repo remove` and `helm plugin remove` are warned
- 🧸 Safe for practice — hard to accidentally blast the wrong thing

---

## 🗺️ Learning Path — 10 Modules · 133 Levels · 34,350 XP

| # | Module | Levels | XP | Difficulty | Key Topics |
|---|--------|--------|----|------------|------------|
| 1 | 🟢 Helm Basics | 15 | 1,900 | Beginner | Chart structure, installs, values, lint |
| 2 | 🟢 Values & Overrides | 15 | 2,700 | Beginner | Type issues, nested keys, `--set`, schema |
| 3 | 🟡 Template Debugging | 20 | 4,900 | Intermediate | Go templates, context, indentation, helpers |
| 4 | 🟡 Release Management | 15 | 3,600 | Intermediate | Failed releases, upgrades, ownership, notes |
| 5 | 🟡 Rollbacks & Recovery | 15 | 4,150 | Intermediate | History, rollback behavior, recovery workflows |
| 6 | 🔴 Chart Dependencies | 13 | 3,450 | Advanced | Locks, subcharts, aliases, dependency updates |
| 7 | 🔴 Helm Hooks | 10 | 2,900 | Advanced | Pre/post hooks, cleanup, ordering, test hooks |
| 8 | 🔴 Security & Linting | 10 | 2,850 | Advanced | RBAC, secrets, deprecated APIs, quotas |
| 9 | ⚫ Advanced Patterns | 10 | 3,600 | Expert | Library charts, OCI, helmfile, post-renderers |
| 10 | ⚫ Production War Games | 10 | 4,300 | Expert | Multi-chart failures, canaries, incidents |

---

## 📁 Project Structure

```text
helmissions/
├── play.sh                     ← Launch the game
├── install.sh                  ← One-time setup
├── requirements.txt            ← Python dependencies
├── engine/
│   ├── engine.py               ← Core game loop
│   ├── ui.py                   ← Rich terminal UI
│   ├── certificate.py          ← Module completion certificates
│   ├── player.py               ← Player state helpers
│   ├── reset.py                ← Level reset logic
│   └── safety.py               ← Helm and kubectl safety guards
├── scripts/
│   ├── build_levels.py         ← Rebuild all levels from PLAN.md
│   └── generate_registry.py    ← Regenerate levels.json registry
├── levels.json                 ← Pre-built level registry
└── modules/
    ├── module-1-basics/
    │   └── level-N-*/
    │       ├── mission.yaml    ← Briefing metadata
    │       ├── broken/         ← Broken chart the player fixes
    │       ├── solution/       ← Reference chart shown by guide
    │       ├── validate.sh     ← Level validator
    │       ├── setup.sh        ← Scenario setup
    │       ├── hint-*.txt      ← Progressive hints
    │       ├── debrief.md      ← Post-level lesson
    │       └── common-mistakes.md
    ├── module-2-values/
    └── ...                     ← modules 3–10
```

---

## 🔄 Resetting Progress

Reset your saved progress from the launcher:

```bash
./play.sh --reset
```

Reset the current level from inside the game with `reset` or shortcut `6`.

---

## 🎓 Post-Mission Debriefs

After every completed mission you unlock a debrief that covers:

- 🔎 What actually broke and why
- 🧠 The Helm concept behind the fix
- 🚨 Where this kind of bug appears in real delivery pipelines
- 🔧 The `helm` and `kubectl` checks that prove the fix worked

---

## 🏗️ Content Generation

HelmMissions is generated from the project plan:

- `PLAN.md` is the source specification for modules and levels
- `scripts/build_levels.py` rebuilds all level folders and `levels.json`
- `scripts/generate_registry.py` refreshes only the registry

This makes it easy to evolve the curriculum without hand-editing 133 level trees.

---

## 📄 License

MIT License.
