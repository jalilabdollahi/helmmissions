#!/usr/bin/env python3
"""Reset helpers for rebuilding level state."""

from __future__ import annotations

import shutil
import subprocess
import sys
import time
from pathlib import Path

from rich.console import Console

console = Console()

NAMESPACE = "helmissions"
SANDBOX_DIRNAME = "sandbox"


def _run(args: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=check)


def _run_best_effort(args: list[str], cwd: Path | None = None) -> None:
    subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=False)


def _wait_for_namespace_deletion(name: str, timeout: int = 45) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        result = subprocess.run(
            ["kubectl", "get", "namespace", name],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            return
        time.sleep(1)
    raise RuntimeError(f"Timed out waiting for namespace '{name}' to delete")


def _cleanup_manifest(level_path: Path, manifest_name: str) -> None:
    manifest = level_path / manifest_name
    if manifest.exists():
        _run_best_effort(["kubectl", "delete", "-f", str(manifest), "--ignore-not-found=true"], cwd=level_path)


def _refresh_sandbox(repo_root: Path, level_path: Path) -> Path:
    """Copy only the active editable files into sandbox/current."""
    sandbox_root = repo_root / SANDBOX_DIRNAME
    current_dir = sandbox_root / "current"
    if current_dir.exists():
        shutil.rmtree(current_dir)
    current_dir.mkdir(parents=True, exist_ok=True)

    broken_dir = level_path / ".broken-source"
    if not broken_dir.exists():
        broken_dir = level_path / "broken"
    if broken_dir.exists():
        shutil.copytree(broken_dir, current_dir / "broken", dirs_exist_ok=True)

    info = (
        f"Active level: {level_path.relative_to(repo_root)}\n"
        f"Original files: {level_path}\n"
        f"Edit here: {current_dir / 'broken'}\n"
        "This sandbox only contains the editable broken chart.\n"
        "Reference files like mission.yaml, hints, validate.sh, and solution/ stay in the original level folder.\n"
        "Use this folder in your second terminal while the game stays open in the first.\n"
    )
    (current_dir / "LEVEL_INFO.txt").write_text(info, encoding="utf-8")
    return current_dir


def prepare_level(repo_root: Path, level_path: Path) -> None:
    """Reset the helmissions namespace and install the broken scenario."""
    sandbox_dir = _refresh_sandbox(repo_root, level_path)
    result = subprocess.run(
        ["helm", "list", "-q", "-n", NAMESPACE],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.stdout.strip():
        for release in result.stdout.strip().splitlines():
            _run_best_effort(["helm", "uninstall", release.strip(), "-n", NAMESPACE])

    _run_best_effort(["kubectl", "delete", "all", "--all", "-n", NAMESPACE])
    _run(["kubectl", "create", "namespace", NAMESPACE], check=False)

    setup_script = level_path / "setup.sh"
    if setup_script.exists():
        _run(["bash", str(setup_script)], cwd=level_path, check=False)
        console.print(f"[grey70]Sandbox refreshed at [bold]{sandbox_dir}[/bold][/grey70]")
        return

    broken_dir = sandbox_dir / "broken"
    if broken_dir.exists():
        _run(
            ["helm", "install", "helmissions-app", str(broken_dir), "-n", NAMESPACE, "--create-namespace"],
            cwd=sandbox_dir,
            check=False,
        )
    console.print(f"[grey70]Sandbox refreshed at [bold]{sandbox_dir}[/bold][/grey70]")


def reset_current_level(repo_root: Path, level_path: Path) -> bool:
    try:
        prepare_level(repo_root, level_path)
    except Exception as exc:  # pragma: no cover - CLI path
        console.print(f"[red]Reset failed:[/red] {exc}")
        return False
    return True


def main() -> int:
    if len(sys.argv) != 2:
        console.print("Usage: python3 engine/reset.py <absolute-level-path>")
        return 1
    repo_root = Path(__file__).resolve().parent.parent
    level_path = Path(sys.argv[1]).resolve()
    return 0 if reset_current_level(repo_root, level_path) else 1


if __name__ == "__main__":
    raise SystemExit(main())
