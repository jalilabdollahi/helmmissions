#!/usr/bin/env python3
"""Level lifecycle: cluster cleanup, sandbox refresh, and running level scripts.

Shared by the game engine and by scripts/test_levels.py so both exercise the
exact same code path.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

from rich.console import Console

console = Console()

REPO_ROOT = Path(__file__).resolve().parent.parent
NAMESPACE = "helmissions"
NAMESPACE_PREFIX = "helmissions-"
CLEANUP_LABEL = "helmissions.io/cleanup=true"
LOCAL_PREFIX = "hm-"  # helm repos / plugins created by levels
DEFAULT_CONTEXT = "kind-helmissions"
CLUSTER_SCOPED_KINDS = (
    "customresourcedefinitions,clusterroles,clusterrolebindings,priorityclasses,"
    "storageclasses,ingressclasses,validatingwebhookconfigurations,"
    "mutatingwebhookconfigurations,persistentvolumes"
)


def expected_context() -> str:
    return os.environ.get("HELMISSIONS_CONTEXT", DEFAULT_CONTEXT)


def sandbox_root() -> Path:
    return Path(os.environ.get("HELMISSIONS_SANDBOX_ROOT", REPO_ROOT / "sandbox"))


def sandbox_dir() -> Path:
    return sandbox_root() / "current"


def _run(args: list[str], timeout: int = 120, **kwargs) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(args, capture_output=True, text=True, check=False, timeout=timeout, **kwargs)
    except subprocess.TimeoutExpired as exc:
        return subprocess.CompletedProcess(args, 124, exc.stdout or "", f"timed out after {timeout}s")
    except FileNotFoundError as exc:
        return subprocess.CompletedProcess(args, 127, "", str(exc))


# ─────────────────────────────────────────────────────────────────────────────
# Kube context guard — never touch a cluster that is not the HelmMissions one
# ─────────────────────────────────────────────────────────────────────────────

def current_context() -> str:
    return _run(["kubectl", "config", "current-context"], timeout=10).stdout.strip()


def context_is_safe() -> bool:
    return current_context() == expected_context()


def switch_context() -> bool:
    return _run(["kubectl", "config", "use-context", expected_context()], timeout=10).returncode == 0


# ─────────────────────────────────────────────────────────────────────────────
# Environment for level scripts
# ─────────────────────────────────────────────────────────────────────────────

def level_env(level_path: Path) -> dict[str, str]:
    env = os.environ.copy()
    env.update(
        {
            "NS": NAMESPACE,
            "LEVEL_DIR": str(level_path),
            "SANDBOX": str(sandbox_dir()),
            "HM_LIB": str(REPO_ROOT / "engine" / "lib" / "common.sh"),
            "HM_ROOT": str(REPO_ROOT),
            "HM_PYTHON": sys.executable,
        }
    )
    env.setdefault("HM_REGISTRY", "localhost:5001")
    env.setdefault("HM_CHARTREPO_URL", "http://localhost:8879")
    env.setdefault("HM_CHARTREPO_DIR", str(REPO_ROOT / ".hm-shared" / "chartrepo"))
    return env


def run_level_script(level_path: Path, script: str, timeout: int = 600) -> subprocess.CompletedProcess[str] | None:
    """Run setup.sh / validate.sh / solve.sh for a level. Returns None if missing."""
    path = level_path / script
    if not path.exists():
        return None
    cwd = sandbox_dir()
    cwd.mkdir(parents=True, exist_ok=True)
    return _run(["bash", str(path)], timeout=timeout, cwd=cwd, env=level_env(level_path))


# ─────────────────────────────────────────────────────────────────────────────
# Cleanup
# ─────────────────────────────────────────────────────────────────────────────

def _game_namespaces() -> list[str]:
    result = _run(["kubectl", "get", "namespaces", "-o", "jsonpath={.items[*].metadata.name}"], timeout=20)
    names = result.stdout.split()
    return [n for n in names if n == NAMESPACE or n.startswith(NAMESPACE_PREFIX)]


def _wait_namespaces_gone(names: list[str], timeout: int = 180) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        remaining = set(_game_namespaces()) & set(names)
        if not remaining:
            return
        time.sleep(1)
    raise RuntimeError(f"Timed out waiting for namespaces to delete: {', '.join(sorted(remaining))}")


def _cleanup_local_helm_state() -> None:
    repos = _run(["helm", "repo", "list", "-o", "json"], timeout=20)
    try:
        for repo in json.loads(repos.stdout or "[]"):
            if repo.get("name", "").startswith(LOCAL_PREFIX):
                _run(["helm", "repo", "remove", repo["name"]], timeout=20)
    except json.JSONDecodeError:
        pass
    plugins = _run(["helm", "plugin", "list"], timeout=20)
    for line in plugins.stdout.splitlines()[1:]:
        name = line.split()[0] if line.split() else ""
        if name.startswith(LOCAL_PREFIX):
            _run(["helm", "plugin", "uninstall", name], timeout=20)
    # A plugin whose plugin.yaml fails to load is invisible to `helm plugin list/uninstall`
    # but still occupies its directory (often a symlink to the source). Remove leftovers directly.
    plugin_dir = _run(["helm", "env", "HELM_PLUGINS"], timeout=10).stdout.strip()
    for root in filter(None, plugin_dir.split(os.pathsep)):
        base = Path(root)
        if not base.is_dir():
            continue
        for entry in base.glob(f"{LOCAL_PREFIX}*"):
            if entry.is_symlink() or entry.is_file():
                entry.unlink(missing_ok=True)
            elif entry.is_dir():
                shutil.rmtree(entry, ignore_errors=True)


def cleanup_cluster() -> None:
    """Remove everything previous levels may have left behind."""
    if not context_is_safe():
        raise RuntimeError(
            f"kubectl context is '{current_context()}', expected '{expected_context()}'. Refusing to reset."
        )
    namespaces = _game_namespaces()
    for ns in namespaces:
        _run(["kubectl", "delete", "pods", "--all", "-n", ns, "--grace-period=0", "--force", "--wait=false"], timeout=30)
    if namespaces:
        _run(["kubectl", "delete", "namespace", *namespaces, "--wait=false"], timeout=60)
    _run(["kubectl", "delete", CLUSTER_SCOPED_KINDS, "-l", CLEANUP_LABEL, "--wait=false"], timeout=60)
    _cleanup_local_helm_state()
    if namespaces:
        _wait_namespaces_gone(namespaces)
    _run(["kubectl", "create", "namespace", NAMESPACE], timeout=30)


# ─────────────────────────────────────────────────────────────────────────────
# Sandbox + setup
# ─────────────────────────────────────────────────────────────────────────────

def refresh_sandbox(level_path: Path) -> Path:
    """Copy the level's broken/ workspace into sandbox/current/."""
    current = sandbox_dir()
    if current.exists():
        shutil.rmtree(current)
    current.mkdir(parents=True, exist_ok=True)
    broken = level_path / "broken"
    if broken.exists():
        shutil.copytree(broken, current, dirs_exist_ok=True)
    try:
        rel = level_path.relative_to(REPO_ROOT)
    except ValueError:
        rel = level_path
    (sandbox_root() / "LEVEL_INFO.txt").write_text(
        f"Active level: {rel}\n"
        f"Workspace:    {current}\n"
        "Edit files in the workspace from your second terminal. Run `reset` in the game to start over.\n",
        encoding="utf-8",
    )
    return current


def prepare_level(repo_root: Path, level_path: Path, quiet: bool = False) -> bool:
    """Reset the cluster and workspace, then build the level scenario.

    Returns True when setup.sh succeeded. ``repo_root`` is kept for backwards compatibility.
    """
    del repo_root
    if not quiet:
        console.print("[grey70]Preparing mission: cleaning cluster state...[/grey70]")
    cleanup_cluster()
    workspace = refresh_sandbox(level_path)
    if not quiet:
        console.print("[grey70]Building the broken scenario...[/grey70]")
    result = run_level_script(level_path, "setup.sh")
    if result is not None and result.returncode != 0:
        console.print(f"[bold red]Level setup failed (exit {result.returncode}).[/bold red]")
        output = (result.stdout + "\n" + result.stderr).strip()
        if output:
            console.print(output[-3000:], markup=False, highlight=False)
        return False
    if not quiet:
        console.print(f"[grey70]Workspace ready at [bold]{workspace}[/bold][/grey70]")
    return True


def main() -> int:
    if len(sys.argv) != 2:
        console.print("Usage: python3 -m engine.reset <level-path>")
        return 1
    level_path = Path(sys.argv[1]).resolve()
    try:
        return 0 if prepare_level(REPO_ROOT, level_path) else 1
    except RuntimeError as exc:
        console.print(f"[red]Reset failed:[/red] {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
