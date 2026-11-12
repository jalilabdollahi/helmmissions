#!/usr/bin/env python3
"""HelmMissions main game loop."""

from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
import time
from pathlib import Path

try:
    import readline  # noqa: F401 — enables arrow keys and history in Prompt.ask()
except ImportError:  # pragma: no cover - Windows
    pass

import yaml
from rich.panel import Panel
from rich.prompt import Confirm, Prompt
from rich.syntax import Syntax
from rich.text import Text

from engine.certificate import generate_certificate, render_certificate_panel, save_certificate
from engine.player import prompt_player_name
from engine.reset import (
    current_context,
    context_is_safe,
    expected_context,
    prepare_level,
    run_level_script,
    sandbox_dir,
    switch_context,
)
from engine.safety import print_safety_info, validate_helm_command, validate_kubectl_command
from engine.ui import (
    console,
    module_title,
    render_markdown,
    show_guidance,
    show_help,
    show_mission_briefing,
    show_module_completion,
    show_post_level_debrief,
    show_status,
    show_victory,
    show_welcome,
)

REPO_ROOT = Path(__file__).resolve().parent.parent
PROGRESS_FILE = REPO_ROOT / "progress.json"
MAX_HINTS = 3


# ─────────────────────────────────────────────────────────────────────────────
# Progress
# ─────────────────────────────────────────────────────────────────────────────

def default_progress(player_name: str = "") -> dict:
    return {
        "player_name": player_name,
        "total_xp": 0,
        "completed_levels": [],
        "skipped_levels": [],
        "current_module": "",
        "current_level": "",
        "module_certificates": [],
        "time_per_level": {},
        "level_start_time": None,
        "hint_progress": {},
    }


def load_progress() -> dict:
    data = default_progress()
    if PROGRESS_FILE.exists():
        try:
            data.update(json.loads(PROGRESS_FILE.read_text(encoding="utf-8")))
        except (json.JSONDecodeError, OSError):
            console.print("[yellow]progress.json is unreadable — starting with fresh progress.[/yellow]")
    return data


def save_progress(progress: dict) -> None:
    tmp = PROGRESS_FILE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(progress, indent=2), encoding="utf-8")
    tmp.replace(PROGRESS_FILE)


# ─────────────────────────────────────────────────────────────────────────────
# Levels
# ─────────────────────────────────────────────────────────────────────────────

def _sort_key(path: Path) -> tuple[int, str]:
    match = re.search(r"(\d+)", path.name)
    return (int(match.group(1)) if match else 9999, path.name)


def load_modules() -> list[dict]:
    """Scan modules/ for levels. Always reads mission.yaml so the game never uses stale data."""
    modules: list[dict] = []
    modules_dir = REPO_ROOT / "modules"
    if not modules_dir.is_dir():
        return modules
    for module_dir in sorted((p for p in modules_dir.iterdir() if p.is_dir()), key=_sort_key):
        levels = []
        for level_dir in sorted((p for p in module_dir.iterdir() if p.is_dir()), key=_sort_key):
            mission_file = level_dir / "mission.yaml"
            if not mission_file.exists():
                continue
            try:
                mission = yaml.safe_load(mission_file.read_text(encoding="utf-8")) or {}
            except yaml.YAMLError as exc:
                console.print(f"[red]Skipping {level_dir.name}: invalid mission.yaml ({exc})[/red]")
                continue
            levels.append(
                {
                    "id": f"{module_dir.name}/{level_dir.name}",
                    "name": level_dir.name,
                    "path": level_dir,
                    "mission": mission,
                }
            )
        if levels:
            modules.append({"name": module_dir.name, "path": module_dir, "levels": levels})
    return modules


def compute_max_xp_by_module(modules: list[dict]) -> dict[str, int]:
    return {m["name"]: sum(int(lv["mission"].get("xp", 0)) for lv in m["levels"]) for m in modules}


def build_module_xp(modules: list[dict], completed_levels: set[str]) -> dict[str, int]:
    return {
        m["name"]: sum(int(lv["mission"].get("xp", 0)) for lv in m["levels"] if lv["id"] in completed_levels)
        for m in modules
    }


def current_position(modules: list[dict], progress: dict) -> tuple[int, int]:
    for module_index, module in enumerate(modules):
        if module["name"] != progress.get("current_module"):
            continue
        for level_index, level in enumerate(module["levels"]):
            if level["name"] == progress.get("current_level"):
                return module_index, level_index
    return 0, 0


def advance(modules: list[dict], module_index: int, level_index: int) -> tuple[int | None, int | None]:
    if level_index + 1 < len(modules[module_index]["levels"]):
        return module_index, level_index + 1
    if module_index + 1 < len(modules):
        return module_index + 1, 0
    return None, None


# ─────────────────────────────────────────────────────────────────────────────
# Cluster checks
# ─────────────────────────────────────────────────────────────────────────────

def _quick(args: list[str]) -> bool:
    try:
        return subprocess.run(args, capture_output=True, text=True, check=False, timeout=15).returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def ensure_cluster() -> bool:
    """Verify helm, the kube context, and cluster reachability."""
    if not _quick(["helm", "version", "--short"]):
        console.print(Panel("[bold red]helm was not found on PATH.[/bold red]\nInstall Helm 3.14+ or 4.x: https://helm.sh/docs/intro/install/",
                            title="[bold red]Helm Missing[/bold red]", border_style="red"))
        return False
    if not context_is_safe():
        ctx = current_context() or "(none)"
        console.print(Panel(
            Text.assemble(
                ("Your kubectl context is ", "white"), (ctx, "bold yellow"),
                (", but HelmMissions only runs against ", "white"), (expected_context(), "bold bright_cyan"), (".\n", "white"),
                ("Resetting a level deletes namespaces, so the game refuses to run on any other cluster.", "grey70"),
            ),
            title="[bold yellow]Kube Context[/bold yellow]", border_style="yellow",
        ))
        if not Confirm.ask(f"Switch the current context to {expected_context()}?", default=True) or not switch_context():
            console.print(f"[red]Run [bold]./install.sh[/bold] to create the cluster, or `kubectl config use-context {expected_context()}`.[/red]")
            return False
    if not _quick(["kubectl", "cluster-info"]):
        console.print(Panel(
            Text.assemble(
                ("The HelmMissions cluster is not reachable.\n\n", "bold red"),
                ("Make sure Docker is running, then run:\n", "white"),
                ("  ./install.sh\n", "bright_cyan"),
            ),
            title="[bold red]Cluster Offline[/bold red]", border_style="red",
        ))
        return False
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Commands
# ─────────────────────────────────────────────────────────────────────────────

def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def show_debrief(level_path: Path) -> None:
    if not (level_path / "debrief.md").exists():
        console.print("[yellow]No debrief available for this level.[/yellow]")
        return
    show_post_level_debrief(level_path)


_LEXERS = {".yaml": "yaml", ".yml": "yaml", ".json": "json", ".tpl": "go", ".txt": "text", ".sh": "bash", ".md": "markdown", ".toml": "toml"}


def show_guide(level_path: Path) -> None:
    guide_path = level_path / "solution-guide.md"
    if guide_path.exists():
        render_markdown("Walkthrough", guide_path.read_text(encoding="utf-8"), "bright_yellow")
    solution_dir = level_path / "solution"
    if solution_dir.is_dir():
        console.print("[bold bright_yellow]Reference files (fixed workspace):[/bold bright_yellow]")
        for file_path in sorted(p for p in solution_dir.rglob("*") if p.is_file()):
            rel_path = file_path.relative_to(solution_dir)
            try:
                content = file_path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                console.print(f"[grey70]── {rel_path} (binary) ──[/grey70]")
                continue
            console.print(f"[bold bright_yellow]── {rel_path} ──[/bold bright_yellow]")
            console.print(Syntax(content, _LEXERS.get(file_path.suffix, "text"), theme="ansi_dark", line_numbers=False))
    elif not guide_path.exists():
        console.print("[yellow]No guide available for this level.[/yellow]")


def run_validator(level_path: Path) -> subprocess.CompletedProcess[str] | None:
    result = run_level_script(level_path, "validate.sh")
    if result is None:
        console.print(f"[red]validate.sh missing in {level_path}[/red]")
    return result


def print_validator_output(result: subprocess.CompletedProcess[str]) -> None:
    if result.stdout:
        console.print(result.stdout.rstrip(), markup=False, highlight=False)
    if result.stderr:
        console.print(result.stderr.rstrip(), style="yellow", markup=False, highlight=False)


def _run_tool(full_command: str) -> None:
    try:
        args = shlex.split(full_command)
    except ValueError as exc:
        console.print(f"[red]Could not parse command: {exc}[/red]")
        return
    try:
        result = subprocess.run(args, capture_output=True, text=True, check=False, cwd=sandbox_dir(), timeout=600)
    except subprocess.TimeoutExpired:
        console.print("[red]Command timed out after 10 minutes.[/red]")
        return
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted.[/yellow]")
        return
    if result.stdout:
        console.print(result.stdout.rstrip(), markup=False, highlight=False)
    if result.stderr:
        console.print(result.stderr.rstrip(), style="red" if result.returncode else "yellow", markup=False, highlight=False)


def run_helm(raw_command: str) -> None:
    full_command = f"helm {raw_command}".strip()
    if validate_helm_command(full_command, interactive=True):
        _run_tool(full_command)


def run_kubectl(raw_command: str) -> None:
    full_command = f"kubectl {raw_command}".strip()
    if validate_kubectl_command(full_command, interactive=True):
        _run_tool(full_command)


def _find_editor() -> str:
    for editor in ("nano", "vim", "vi"):
        if subprocess.run(["which", editor], capture_output=True, check=False).returncode == 0:
            return editor
    return "vi"


def run_edit_resource(resource_spec: str) -> None:
    """Dump a live resource to a temp YAML file, open it in $EDITOR, then kubectl apply."""
    parts = resource_spec.strip().split()
    if not parts:
        console.print("[yellow]Usage: edit <type> <name> [-n namespace]  (e.g.  edit configmap webapp-config)[/yellow]")
        return
    namespace = "helmissions"
    filtered: list[str] = []
    i = 0
    while i < len(parts):
        if parts[i] in ("-n", "--namespace") and i + 1 < len(parts):
            namespace = parts[i + 1]
            i += 2
        elif parts[i].startswith("--namespace="):
            namespace = parts[i].split("=", 1)[1]
            i += 1
        else:
            filtered.append(parts[i])
            i += 1
    result = subprocess.run(["kubectl", "get", *filtered, "-n", namespace, "-o", "yaml"], capture_output=True, text=True, check=False)
    if result.returncode != 0:
        console.print(result.stderr.rstrip(), style="red", markup=False)
        return
    try:
        doc = yaml.safe_load(result.stdout) or {}
        doc.pop("status", None)
        meta = doc.get("metadata", {})
        for field in ("resourceVersion", "uid", "creationTimestamp", "generation", "managedFields"):
            meta.pop(field, None)
        annotations = meta.get("annotations") or {}
        annotations.pop("kubectl.kubernetes.io/last-applied-configuration", None)
        if not annotations:
            meta.pop("annotations", None)
        clean = yaml.safe_dump(doc, default_flow_style=False, allow_unicode=True, sort_keys=False)
    except yaml.YAMLError:
        clean = result.stdout
    with tempfile.NamedTemporaryFile(suffix=".yaml", prefix="helmissions-", mode="w", delete=False, encoding="utf-8") as tmp:
        tmp.write(clean)
        tmp_path = tmp.name
    console.print(f"[grey70]Resource written to [bold]{tmp_path}[/bold] — opening editor...[/grey70]")
    editor = os.environ.get("EDITOR") or os.environ.get("VISUAL") or _find_editor()
    start = time.time()
    subprocess.run([*shlex.split(editor), tmp_path], check=False)
    if time.time() - start < 2.0:
        console.print(f"[yellow]If you opened a GUI editor, finish editing [bold]{tmp_path}[/bold] then press Enter.[/yellow]")
        try:
            input()
        except EOFError:
            pass
    if not Confirm.ask("[bold bright_cyan]Apply edited manifest?[/bold bright_cyan]", default=True):
        console.print(f"[grey70]Cancelled. Temp file at {tmp_path}[/grey70]")
        return
    apply = subprocess.run(["kubectl", "apply", "-f", tmp_path], capture_output=True, text=True, check=False)
    if apply.stdout:
        console.print(apply.stdout.rstrip(), markup=False)
    if apply.returncode == 0:
        console.print("[bright_green]✅ Changes applied. Note: Helm will overwrite manual edits on the next upgrade.[/bright_green]")
        os.unlink(tmp_path)
        return
    console.print(apply.stderr.rstrip(), style="red", markup=False)
    console.print(f"[grey70]Temp file kept at {tmp_path}[/grey70]")


# ─────────────────────────────────────────────────────────────────────────────
# Level flow
# ─────────────────────────────────────────────────────────────────────────────

def ensure_player_name(progress: dict) -> None:
    if not progress.get("player_name"):
        progress["player_name"] = prompt_player_name("")
        save_progress(progress)


def ensure_current_level(progress: dict, modules: list[dict]) -> None:
    if not modules:
        raise RuntimeError("No levels were found in modules/")
    module_index, level_index = current_position(modules, progress)
    progress["current_module"] = modules[module_index]["name"]
    progress["current_level"] = modules[module_index]["levels"][level_index]["name"]
    save_progress(progress)


def start_level(level: dict) -> None:
    if not prepare_level(REPO_ROOT, level["path"]):
        console.print("[yellow]The scenario may be incomplete. Type [bold]reset[/bold] to retry the setup.[/yellow]")


def award_module_certificate(progress: dict, modules: list[dict], module_index: int) -> None:
    module = modules[module_index]
    if module["name"] in progress.get("module_certificates", []):
        return
    completed = set(progress.get("completed_levels", []))
    if not {lv["id"] for lv in module["levels"]}.issubset(completed):
        return  # skipped levels do not count
    module_xp = sum(int(lv["mission"].get("xp", 0)) for lv in module["levels"])
    title = module_title(module["name"])
    save_certificate(REPO_ROOT, module["name"], generate_certificate(progress["player_name"], module["name"], title, module_xp))
    progress.setdefault("module_certificates", []).append(module["name"])
    save_progress(progress)
    show_module_completion(render_certificate_panel(progress["player_name"], title, module["name"], module_xp))


def complete_level(progress: dict, modules: list[dict], module_index: int, level_index: int, award_xp: bool) -> bool:
    """Record completion (or skip), show debrief, and move to the next level. Returns False at the end."""
    level = modules[module_index]["levels"][level_index]
    level_id = level["id"]
    completed = set(progress.get("completed_levels", []))
    skipped = set(progress.get("skipped_levels", []))
    xp = int(level["mission"].get("xp", 0)) if award_xp and level_id not in completed else 0

    elapsed_seconds: int | None = None
    start_ts = progress.get("level_start_time")
    if start_ts is not None and award_xp:
        elapsed_seconds = max(0, int(time.time() - start_ts))
        progress.setdefault("time_per_level", {})[level_id] = elapsed_seconds
    progress["level_start_time"] = None

    if award_xp:
        completed.add(level_id)
        skipped.discard(level_id)
    elif level_id not in completed:
        skipped.add(level_id)
    progress["completed_levels"] = sorted(completed)
    progress["skipped_levels"] = sorted(skipped)
    progress["total_xp"] = int(progress.get("total_xp", 0)) + xp
    save_progress(progress)

    show_victory(
        modules[module_index]["name"], level["mission"].get("name", level["name"]), xp, progress["total_xp"],
        skipped=not award_xp, elapsed_seconds=elapsed_seconds, expected_time=level["mission"].get("expected_time"),
    )
    if award_xp:
        show_post_level_debrief(level["path"], elapsed_seconds=elapsed_seconds, expected_time=level["mission"].get("expected_time"))
        award_module_certificate(progress, modules, module_index)

    next_module, next_level = advance(modules, module_index, level_index)
    if next_module is None:
        left = len(progress["skipped_levels"])
        msg = "All missions complete. Mission Control salutes you."
        if left:
            msg += f" ({left} skipped level(s) are still waiting — use [bold]goto[/bold] to revisit them.)"
        console.print(f"[bold bright_green]{msg}[/bold bright_green]")
        return False
    progress["current_module"] = modules[next_module]["name"]
    progress["current_level"] = modules[next_module]["levels"][next_level]["name"]
    progress["level_start_time"] = time.time()
    save_progress(progress)
    start_level(modules[next_module]["levels"][next_level])
    return True


def goto_level(progress: dict, modules: list[dict], target: str) -> bool:
    """Jump to a level by 'M.L' (e.g. 3.7) or by level id substring."""
    match = re.fullmatch(r"(\d+)\.(\d+)", target.strip())
    found: tuple[int, int] | None = None
    if match:
        mi, li = int(match.group(1)) - 1, int(match.group(2)) - 1
        if 0 <= mi < len(modules) and 0 <= li < len(modules[mi]["levels"]):
            found = (mi, li)
    else:
        for mi, module in enumerate(modules):
            for li, level in enumerate(module["levels"]):
                if target and target in level["id"]:
                    found = (mi, li)
                    break
            if found:
                break
    if not found:
        console.print("[yellow]Level not found. Use module.level numbers, e.g. [bold]goto 3.7[/bold].[/yellow]")
        return False
    mi, li = found
    progress["current_module"] = modules[mi]["name"]
    progress["current_level"] = modules[mi]["levels"][li]["name"]
    progress["level_start_time"] = time.time()
    save_progress(progress)
    start_level(modules[mi]["levels"][li])
    return True


_KUBECTL_VERBS = frozenset({
    "get", "describe", "logs", "exec", "apply", "delete", "patch", "scale", "rollout", "set", "label",
    "annotate", "top", "drain", "cordon", "uncordon", "port-forward", "proxy", "cp", "auth", "config", "create", "events",
})
_HELM_VERBS = frozenset({
    "install", "upgrade", "uninstall", "list", "ls", "status", "rollback", "history", "get", "show", "pull", "push",
    "repo", "dependency", "dep", "template", "lint", "test", "plugin", "search", "verify", "package", "registry", "create",
})
_NUMBER_CMDS = {
    "1": "check", "d": "check-dry", "w": "watch", "2": "hint", "3": "guide", "4": "debrief",
    "6": "reset", "7": "status", "8": "skip", "9": "quit", "0": "reset-progress",
}


def watch_mode(level_path: Path) -> bool:
    interval = 5
    console.print(Panel(
        Text.assemble(("Watch mode active — ", "bright_cyan"), ("validator runs every 5s", "white"), ("  •  ", "grey50"), ("Ctrl+C to cancel", "grey70")),
        border_style="bright_cyan", padding=(0, 1),
    ))
    attempt = 0
    try:
        while True:
            attempt += 1
            result = run_validator(level_path)
            if result is None:
                return False
            if result.returncode == 0:
                print_validator_output(result)
                console.print(f"[bold bright_green]✅ Passed on attempt {attempt}[/bold bright_green]")
                return True
            last = [ln for ln in result.stdout.splitlines() if ln.startswith("❌")]
            reason = last[-1] if last else "not passing yet"
            for remaining in range(interval, 0, -1):
                console.print(f"\r[grey70]  ↺ Attempt {attempt}: {reason[:70]} — rechecking in {remaining}s [/grey70]", end="")
                time.sleep(1)
            console.print()
    except KeyboardInterrupt:
        console.print("\n[yellow]Watch mode cancelled.[/yellow]")
        return False


def game_loop() -> int:
    console.print("[grey70]Checking cluster health...[/grey70]")
    if not ensure_cluster():
        return 1

    modules = load_modules()
    progress = load_progress()
    ensure_player_name(progress)
    ensure_current_level(progress, modules)

    completed = set(progress.get("completed_levels", []))
    max_xp_by_module = compute_max_xp_by_module(modules)
    show_welcome(progress["player_name"], int(progress.get("total_xp", 0)), modules, completed,
                 build_module_xp(modules, completed), max_xp_by_module, sum(max_xp_by_module.values()))
    console.print(
        "[grey70]Tip: keep HelmMissions open in this terminal and use a second terminal for [bold]helm[/bold] and "
        f"[bold]kubectl[/bold]. Your editable workspace is [bold]{sandbox_dir()}[/bold] — it is rebuilt for every level.[/grey70]"
    )

    module_index, level_index = current_position(modules, progress)
    start_level(modules[module_index]["levels"][level_index])
    if not progress.get("level_start_time"):
        progress["level_start_time"] = time.time()
        save_progress(progress)

    while True:
        modules = load_modules()
        progress = load_progress()
        module_index, level_index = current_position(modules, progress)
        current_level = modules[module_index]["levels"][level_index]
        level_id = current_level["id"]
        level_path = current_level["path"]
        hint_index = int(progress.get("hint_progress", {}).get(level_id, 0))
        show_mission_briefing(module_index + 1, len(modules), level_index + 1, len(modules[module_index]["levels"]),
                              current_level["mission"], workspace=str(sandbox_dir()))
        show_help()

        while True:
            try:
                command = Prompt.ask("[bold bright_cyan]mission-control[/bold bright_cyan]", default="check").strip()
            except EOFError:
                return 0
            if not command:
                continue
            if command.startswith("5k "):
                run_kubectl(command[3:])
                continue
            if command.startswith("5 "):
                run_helm(command[2:])
                continue
            if command in {"5", "5k"}:
                tool = "kubectl" if command == "5k" else "helm"
                console.print(f"[yellow]Usage: {command} <{tool} args>  (e.g.  {command} {'get pods -n helmissions' if tool == 'kubectl' else 'list -n helmissions'})[/yellow]")
                continue
            command = _NUMBER_CMDS.get(command, command)

            if command in {"quit", "exit"}:
                save_progress(progress)
                return 0
            if command in {"help", "?"}:
                show_help()
                continue
            if command == "briefing":
                break
            if command == "status":
                completed = set(progress.get("completed_levels", []))
                max_xp_by_module = compute_max_xp_by_module(modules)
                show_status(modules, completed, build_module_xp(modules, completed), int(progress.get("total_xp", 0)),
                            max_xp_by_module, sum(max_xp_by_module.values()), skipped=set(progress.get("skipped_levels", [])))
                continue
            if command == "debrief":
                show_debrief(level_path)
                continue
            if command == "guide":
                show_guide(level_path)
                continue
            if command == "hint":
                if hint_index >= MAX_HINTS:
                    console.print("[yellow]All hints used. Type [bold]guide[/bold] for the full walkthrough.[/yellow]")
                    continue
                hint_index += 1
                progress.setdefault("hint_progress", {})[level_id] = hint_index
                save_progress(progress)
                hint_path = level_path / f"hint-{hint_index}.txt"
                if hint_path.exists():
                    show_guidance(f"Hint {hint_index}/{MAX_HINTS}", [read_text(hint_path)])
                else:
                    console.print("[yellow]No hint file found. Type [bold]guide[/bold] for the walkthrough.[/yellow]")
                continue
            if command == "reset":
                start_level(current_level)
                hint_index = 0
                progress.setdefault("hint_progress", {})[level_id] = 0
                progress["level_start_time"] = time.time()
                save_progress(progress)
                console.print("[green]Level reset complete.[/green]")
                continue
            if command in {"check", "watch"}:
                if command == "check":
                    console.print("[grey70]Running validator...[/grey70]")
                    result = run_validator(level_path)
                    if result is None:
                        continue
                    print_validator_output(result)
                    passed = result.returncode == 0
                else:
                    passed = watch_mode(level_path)
                if passed:
                    if complete_level(progress, modules, module_index, level_index, award_xp=True):
                        break
                    return 0
                continue
            if command == "check-dry":
                result = run_validator(level_path)
                if result is None:
                    continue
                console.print("[bold grey70]── Dry Run (no XP awarded) ──[/bold grey70]")
                print_validator_output(result)
                verdict = "[bright_green]WOULD PASS[/bright_green]" if result.returncode == 0 else "[red]WOULD FAIL[/red]"
                console.print(f"[grey70]Exit code {result.returncode} → {verdict}[/grey70]")
                continue
            if command == "skip":
                if not Confirm.ask("Skip this level? No XP is awarded and the module certificate will need it later.", default=False):
                    continue
                if complete_level(progress, modules, module_index, level_index, award_xp=False):
                    break
                return 0
            if command.startswith("goto"):
                target = command[4:].strip()
                if target and goto_level(progress, modules, target):
                    break
                if not target:
                    console.print("[yellow]Usage: goto <module>.<level>  (e.g.  goto 3.7)[/yellow]")
                continue
            if command == "reset-progress":
                if Prompt.ask("[bold bright_red]⚠️  Wipe ALL progress and start over? [y/N][/bold bright_red]", default="N").strip().lower() == "y":
                    progress = default_progress(progress.get("player_name", ""))
                    progress["level_start_time"] = time.time()
                    save_progress(progress)
                    ensure_current_level(progress, modules)
                    start_level(modules[0]["levels"][0])
                    console.print("[bright_green]✅ Progress reset. Restarting from Module 1 Level 1.[/bright_green]")
                    break
                console.print("[grey70]Cancelled.[/grey70]")
                continue
            if command == "safety":
                print_safety_info()
                continue
            if command.startswith("helm "):
                run_helm(command[len("helm "):])
                continue
            if command.startswith("kubectl "):
                run_kubectl(command[len("kubectl "):])
                continue
            if command in {"edit", "e"}:
                console.print("[yellow]Usage: edit <type> <name>  (e.g.  edit configmap webapp-config)[/yellow]")
                continue
            if command.startswith("edit "):
                run_edit_resource(command[5:])
                continue
            if command.startswith("e "):
                run_edit_resource(command[2:])
                continue

            first_word = command.split()[0]
            if first_word in _HELM_VERBS:
                console.print(f"[yellow]Tip: prefix helm commands with [bold]helm[/bold] or [bold]5[/bold], e.g. [bright_cyan]helm {command}[/bright_cyan][/yellow]")
                continue
            if first_word in _KUBECTL_VERBS:
                console.print(f"[yellow]Tip: prefix kubectl commands with [bold]kubectl[/bold] or [bold]5k[/bold], e.g. [bright_cyan]kubectl {command}[/bright_cyan][/yellow]")
                continue
            console.print("[yellow]Unknown command. Type 'help' for the available actions.[/yellow]")


def main() -> int:
    try:
        return game_loop()
    except KeyboardInterrupt:
        console.print("\n[grey70]Progress saved. See you next mission.[/grey70]")
        return 130
    except RuntimeError as exc:
        console.print(f"[red]{exc}[/red]")
        return 1


if __name__ == "__main__":
    sys.exit(main())
