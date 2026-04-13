#!/bin/bash
set -e

echo "🚀 HelmMissions Installation"
echo "============================="
echo ""

if [ -x "./bin/helm" ]; then
  export PATH="$(pwd)/bin:$PATH"
fi

command -v kind    >/dev/null || { echo "❌ kind not found.    Install: brew install kind"; exit 1; }
command -v kubectl >/dev/null || { echo "❌ kubectl not found. Install: brew install kubectl"; exit 1; }
command -v helm    >/dev/null || {
  echo "❌ helm not found."
  echo "   Option 1: place a local binary at ./bin/helm"
  echo "   Option 2: install globally from https://helm.sh/docs/intro/install/"
  exit 1
}
command -v python3 >/dev/null || { echo "❌ python3 not found"; exit 1; }

HELM_MAJOR=$(helm version --short | grep -oE 'v[0-9]+' | tr -d 'v' | head -n1)
if [[ -z "$HELM_MAJOR" || "$HELM_MAJOR" -lt 3 ]]; then
  echo "❌ Helm 3+ required (found $(helm version --short))"
  exit 1
fi
echo "✅ Helm $(helm version --short)"

if [ ! -d "venv" ]; then
  python3 -m venv venv
fi
source venv/bin/activate
pip install -q -r requirements.txt
echo "✅ Python packages installed"

CLUSTER_NAME="helmissions"
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "✅ Cluster '${CLUSTER_NAME}' already exists"
else
  echo "🔧 Creating cluster '${CLUSTER_NAME}'..."
  kind create cluster --name "${CLUSTER_NAME}"
fi

kubectl config use-context "kind-${CLUSTER_NAME}"
kubectl create namespace "${CLUSTER_NAME}" --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "════════════════════════════════════"
echo "✅  HelmMissions is ready!"
echo "   Run:  ./play.sh"
echo "════════════════════════════════════"
