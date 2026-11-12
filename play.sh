#!/bin/bash
# HelmMissions launcher
cd "$(dirname "$0")" || exit 1

if [[ "${1:-}" == "--reset" ]]; then
  if [ ! -f "progress.json" ]; then
    echo "ℹ️  No progress file found — nothing to reset."
    exit 0
  fi
  read -r -p "⚠️  Reset all progress? This cannot be undone. [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    python3 - <<'PY'
import json
try:
    name = json.load(open("progress.json")).get("player_name", "")
except Exception:
    name = ""
json.dump({"player_name": name, "total_xp": 0, "completed_levels": [], "skipped_levels": [],
           "current_module": "", "current_level": "", "module_certificates": [],
           "time_per_level": {}, "level_start_time": None, "hint_progress": {}},
          open("progress.json", "w"), indent=2)
PY
    echo "✅ Progress reset. Starting from Module 1 Level 1."
  else
    echo "Cancelled."
    exit 0
  fi
fi

if [ ! -x "venv/bin/python3" ]; then
  echo "❌ Virtual environment not found. Run ./install.sh first."
  exit 1
fi
for tool in helm kubectl jq docker; do
  command -v "$tool" >/dev/null 2>&1 || { echo "❌ '$tool' not found on PATH. Run ./install.sh for details."; exit 1; }
done

clear
export PYTHONPATH="$(pwd)${PYTHONPATH:+:$PYTHONPATH}"
exec venv/bin/python3 -m engine.engine
