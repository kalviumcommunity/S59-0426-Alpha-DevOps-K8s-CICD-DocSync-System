#!/usr/bin/env bash
# DocSync — read-only Deployment / ReplicaSet / Pod inspection (Sprint #3 · PR16)
# Does not apply, scale, restart, or roll back any resources.

set -uo pipefail

banner() {
  echo ""
  echo "══════════════════════════════════════════════════════════════"
  echo "  $*"
  echo "══════════════════════════════════════════════════════════════"
}

if ! command -v kubectl &>/dev/null; then
  echo "[missing] kubectl not found in PATH"
  exit 1
fi

DEPLOY_NAME="${DEPLOY_NAME:-docsync}"

banner "Deployments"

kubectl get deployments -o wide 2>&1 || echo "[warn] kubectl get deployments failed."

banner "ReplicaSets (docsync-related)"

kubectl get rs -l app=docsync -o wide 2>&1 || kubectl get rs -o wide 2>&1 || echo "[warn] kubectl get rs failed."

banner "Pods (app=docsync)"

kubectl get pods -l app=docsync -o wide --show-labels 2>&1 || kubectl get pods -o wide 2>&1 || echo "[warn] kubectl get pods failed."

banner "Rollout status (non-blocking)"

if kubectl get deployment "$DEPLOY_NAME" &>/dev/null; then
  kubectl rollout status "deployment/$DEPLOY_NAME" --timeout=15s 2>&1 || true
else
  echo "[info] Deployment '$DEPLOY_NAME' not found in current namespace — skipping rollout status."
fi

banner "Deployment health summary"

if kubectl get deployment "$DEPLOY_NAME" &>/dev/null; then
  kubectl get deployment "$DEPLOY_NAME" -o custom-columns="NAME:.metadata.name,DESIRED:.spec.replicas,READY:.status.readyReplicas,UPDATED:.status.updatedReplicas,AVAILABLE:.status.availableReplicas,AGE:.metadata.creationTimestamp" 2>&1 || true
  echo ""
  echo "--- conditions ---"
  kubectl get deployment "$DEPLOY_NAME" -o jsonpath='{range .status.conditions[*]}{.type}{"="}{.status}{" ("}{.reason}{") "}{.message}{"\n"}{end}' 2>/dev/null || echo "(conditions unavailable)"
else
  echo "[info] No Deployment '$DEPLOY_NAME' in current namespace."
fi

banner "Done — no cluster modifications were performed."
