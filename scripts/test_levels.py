#!/usr/bin/env python3
"""End-to-end level tester.

For every selected level:
  1. static checks  (mission.yaml fields, hints, debrief, guide, bash -n on scripts)
  2. reset cluster + workspace, run setup.sh          (must exit 0)
  3. run validate.sh on the broken state              (must FAIL)
  4. run solve.sh (reference solution)                (must exit 0)
  5. run validate.sh again                            (must PASS)
  6. optional: tests/*.sh "alternative fix" scripts — each is run from a fresh
     setup and validate.sh must PASS afterwards (proves validators accept other
     correct fixes). tests/fail-*.sh scripts must leave validate.sh FAILING
     (proves validators reject wrong/partial fixes).

Usage:
  venv/bin/python scripts/test_levels.py modules/module-1-basics/level-3-image-tag-typo
  venv/bin/python scripts/test_levels.py --module module-1-basics
  venv/bin/python scripts/test_levels.py --all
  venv/bin/python scripts/test_levels.py --static-only --all
Environment: HELMISSIONS_CONTEXT, HELMISSIONS_SANDBOX_ROOT (see scripts/agent_env.sh).
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import yaml  # noqa: E402

from engine.reset import context_is_safe, current_context, expected_context, prepare_level, run_level_script  # noqa: E402

REQUIRED_MISSION_KEYS = ("name", "description", "objective", "xp", "difficulty", "expected_time", "concepts")
DIFFICULTIES = {"beginner", "intermediate", "advanced", "expert"}
REQUIRED_FILES = ("mission.yaml", "setup.sh", "validate.sh", "solve.sh", "hint-1.txt", "hint-2.txt", "hint-3.txt",
                  "debrief.md", "solution-guide.md")


def _sort_key(path: Path) -> tuple[int, str]:
    match = re.search(r"(\d+)", path.name)
    return (int(match.group(1)) if match else 9999, path.name)


def collect(args: argparse.Namespace) -> list[Path]:
    modules_dir = ROOT / "modules"
    levels: list[Path] = []
    if args.all:
        for module in sorted((p for p in modules_dir.iterdir() if p.is_dir()), key=_sort_key):
            levels += sorted((p for p in module.iterdir() if (p / "mission.yaml").exists()), key=_sort_key)
    if args.module:
        module = modules_dir / args.module
        levels += sorted((p for p in module.iterdir() if (p / "mission.yaml").exists()), key=_sort_key)
    for raw in args.levels:
        levels.append(Path(raw).resolve())
    return levels


def static_check(level: Path) -> list[str]:
    problems: list[str] = []
    for name in REQUIRED_FILES:
        if not (level / name).exists():
            problems.append(f"missing {name}")
    mission_path = level / "mission.yaml"
    if mission_path.exists():
        try:
            mission = yaml.safe_load(mission_path.read_text(encoding="utf-8")) or {}
        except yaml.YAMLError as exc:
            return problems + [f"mission.yaml invalid: {exc}"]
        for key in REQUIRED_MISSION_KEYS:
            if key not in mission or mission[key] in (None, "", []):
                problems.append(f"mission.yaml missing '{key}'")
        if not isinstance(mission.get("xp"), int):
            problems.append("mission.yaml xp must be an integer")
        if mission.get("difficulty") not in DIFFICULTIES:
            problems.append(f"mission.yaml difficulty must be one of {sorted(DIFFICULTIES)}")
        if not isinstance(mission.get("concepts"), list):
            problems.append("mission.yaml concepts must be a list")
    for script in ("setup.sh", "validate.sh", "solve.sh", *[str(p.relative_to(level)) for p in (level / "tests").glob("*.sh")]):
        path = level / script
        if path.exists():
            res = subprocess.run(["bash", "-n", str(path)], capture_output=True, text=True, check=False)
            if res.returncode != 0:
                problems.append(f"{script}: bash syntax error: {res.stderr.strip()}")
            text = path.read_text(encoding="utf-8")
            if 'source "$HM_LIB"' not in text:
                problems.append(f"{script}: must `source \"$HM_LIB\"`")
            if re.search(r"--kube-context|--context[ =]|kind-helmissions", text):
                problems.append(f"{script}: must not pin a kube context")
    for hint in ("hint-1.txt", "hint-2.txt", "hint-3.txt"):
        path = level / hint
        if path.exists() and len(path.read_text(encoding="utf-8").strip()) < 40:
            problems.append(f"{hint} is too short")
    debrief = level / "debrief.md"
    if debrief.exists() and len(debrief.read_text(encoding="utf-8")) < 800:
        problems.append("debrief.md is too short (< 800 chars)")
    return problems


def _tail(res: subprocess.CompletedProcess[str] | None, lines: int = 30) -> str:
    if res is None:
        return "(script missing)"
    text = (res.stdout or "") + ("\n" + res.stderr if res.stderr else "")
    return "\n".join("      " + ln for ln in text.strip().splitlines()[-lines:])


def e2e(level: Path, verbose: bool) -> list[str]:
    problems: list[str] = []

    def setup() -> bool:
        if not prepare_level(ROOT, level, quiet=True):
            problems.append("setup.sh failed")
            return False
        return True

    t0 = time.time()
    if not setup():
        return problems
    t_setup = time.time() - t0

    res = run_level_script(level, "validate.sh")
    if res is None:
        return problems + ["validate.sh missing"]
    if res.returncode == 0:
        problems.append("validate.sh PASSES on the broken state (it must fail)\n" + _tail(res))
    elif verbose:
        print("    broken-state validator output:\n" + _tail(res, 8))

    res = run_level_script(level, "solve.sh")
    if res is None or res.returncode != 0:
        return problems + ["solve.sh failed\n" + _tail(res)]
    res = run_level_script(level, "validate.sh")
    if res is None or res.returncode != 0:
        problems.append("validate.sh FAILS after solve.sh (it must pass)\n" + _tail(res))
    elif verbose:
        print("    solved-state validator output:\n" + _tail(res, 8))

    for alt in sorted((level / "tests").glob("*.sh")):
        must_fail = alt.name.startswith("fail-")
        if not setup():
            break
        res = run_level_script(level, f"tests/{alt.name}")
        if res is None or res.returncode != 0:
            problems.append(f"tests/{alt.name} itself failed\n" + _tail(res))
            continue
        res = run_level_script(level, "validate.sh")
        passed = res is not None and res.returncode == 0
        if must_fail and passed:
            problems.append(f"validate.sh PASSES after tests/{alt.name} (wrong fix must be rejected)\n" + _tail(res))
        if not must_fail and not passed:
            problems.append(f"validate.sh FAILS after alternative fix tests/{alt.name}\n" + _tail(res))
    if verbose:
        print(f"    timings: setup {t_setup:.0f}s, total {time.time() - t0:.0f}s")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("levels", nargs="*")
    parser.add_argument("--module")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--static-only", action="store_true")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()
    levels = collect(args)
    if not levels:
        parser.error("no levels selected")
    if not args.static_only and not context_is_safe():
        print(f"❌ kubectl context is '{current_context()}', expected '{expected_context()}'")
        return 2

    failures = 0
    for level in levels:
        rel = level.relative_to(ROOT) if level.is_relative_to(ROOT) else level
        start = time.time()
        problems = static_check(level)
        if not args.static_only and not problems:
            problems += e2e(level, args.verbose)
        status = "PASS" if not problems else "FAIL"
        print(f"[{status}] {rel}  ({time.time() - start:.0f}s)", flush=True)
        for problem in problems:
            print(f"    - {problem}", flush=True)
        failures += bool(problems)
    print(f"\n{len(levels) - failures}/{len(levels)} levels passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
