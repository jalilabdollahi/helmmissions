#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

echo "🚀 HelmMissions Installation"
echo "============================="

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ $1 not found. Install: $2"; exit 1; }; }
need docker  "https://www.docker.com/products/docker-desktop/ (and start it)"
need kind    "brew install kind"
need kubectl "brew install kubectl"
need helm    "brew install helm"
need jq      "brew install jq"
need python3 "brew install python"
docker info >/dev/null 2>&1 || { echo "❌ Docker is not running. Start Docker Desktop and retry."; exit 1; }

HELM_VERSION="$(helm version --short)"
HELM_MAJOR="$(echo "$HELM_VERSION" | sed -E 's/^v([0-9]+)\.([0-9]+).*/\1/')"
HELM_MINOR="$(echo "$HELM_VERSION" | sed -E 's/^v([0-9]+)\.([0-9]+).*/\2/')"
if [ "$HELM_MAJOR" -lt 3 ] || { [ "$HELM_MAJOR" -eq 3 ] && [ "$HELM_MINOR" -lt 14 ]; }; then
  echo "❌ Helm 3.14+ or Helm 4 required (found $HELM_VERSION)"
  exit 1
fi
echo "✅ Helm $HELM_VERSION"

if [ ! -x venv/bin/python3 ]; then
  python3 -m venv venv
fi
venv/bin/python3 -m pip install -q --disable-pip-version-check -r requirements.txt
echo "✅ Python packages installed"

bash scripts/cluster.sh create helmissions
kubectl config use-context kind-helmissions >/dev/null
kubectl create namespace helmissions --dry-run=client -o yaml | kubectl apply -f - >/dev/null

echo ""
echo "════════════════════════════════════"
echo "✅  HelmMissions is ready!"
echo "   Run:  ./play.sh"
echo "════════════════════════════════════"
