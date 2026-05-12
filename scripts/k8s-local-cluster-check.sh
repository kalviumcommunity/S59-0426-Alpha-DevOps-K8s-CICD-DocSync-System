#!/usr/bin/env bash
# DocSync — read-only local Kubernetes environment check (Sprint #3 · PR14)
# Does NOT create/delete clusters or change kubeconfig beyond read-only queries.

set -uo pipefail

banner() {
  echo ""
  echo "══════════════════════════════════════════════════════════════"
  echo "  $*"
  echo "══════════════════════════════════════════════════════════════"
}

banner "Prerequisite binaries"

if command -v kubectl &>/dev/null; then
  echo "[ok] kubectl: $(kubectl version --client -o yaml 2>/dev/null | grep gitVersion | head -n1 || kubectl version --client 2>&1 | head -n1)"
else
  echo "[missing] kubectl not found in PATH"
fi

if command -v kind &>/dev/null; then
  echo "[ok] kind: $(kind version 2>/dev/null | head -n3 | tr '\n' ' ')"
else
  echo "[info] kind not found (optional if you use minikube/k3s only)"
fi

if command -v minikube &>/dev/null; then
  echo "[ok] minikube: $(minikube version 2>/dev/null | head -n1)"
else
  echo "[info] minikube not found (optional if you use kind/k3s only)"
fi

if ! command -v kind &>/dev/null && ! command -v minikube &>/dev/null; then
  echo "[warn] Neither kind nor minikube in PATH — install one for Assignment 4.19 local clusters (k3s uses a different install path)."
fi

if ! command -v kubectl &>/dev/null; then
  echo ""
  echo "[stop] Install kubectl before applying manifests. See assignment A-14."
  exit 1
fi

banner "kubectl configuration (read-only)"

echo "[info] current-context:"
kubectl config current-context 2>&1 || echo "(none — configure a cluster or run kind/minikube)"

echo ""
echo "[info] contexts:"
kubectl config get-contexts 2>&1 || true

banner "Cluster reachability"

if kubectl cluster-info &>/dev/null; then
  kubectl cluster-info
else
  echo "[warn] kubectl cluster-info failed — no reachable API server for current context?"
fi

banner "Nodes"

kubectl get nodes -o wide 2>&1 || echo "[warn] kubectl get nodes failed (no cluster or insufficient RBAC)."

banner "Pods (all namespaces)"

kubectl get pods -A 2>&1 || echo "[warn] kubectl get pods -A failed."

banner "Done — no cluster create/delete/modify was performed."
