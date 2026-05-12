#!/usr/bin/env bash
# DocSync — read-only Pod / ReplicaSet inspection (Sprint #3 · PR15)
# Does not apply, delete, or scale any resources.

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

banner "Pods (wide + labels)"

kubectl get pods -o wide --show-labels 2>&1 || echo "[warn] kubectl get pods failed."

banner "ReplicaSets"

kubectl get rs -o wide 2>&1 || echo "[warn] kubectl get rs failed."

banner "Per-Pod status (phase + container ready)"

pods=$(kubectl get pods -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
if [[ -z "${pods// }" ]]; then
  echo "(no Pods in current namespace)"
else
  for po in $pods; do
    printf '%s: ' "$po"
    kubectl get pod "$po" -o jsonpath='{.status.phase}{" | "}{range .status.containerStatuses[*]}{.name}{" ready="}{.ready}{" "}{end}{"\n"}' 2>/dev/null || echo "(describe unavailable)"
  done
fi

banner "Pod labels (detail)"

kubectl get pods -o=jsonpath='{range .items[*]}{.metadata.name}{": "}{range $k,$v := .metadata.labels}{$k}{"="}{$v}{" "}{end}{"\n"}{end}' 2>&1 || echo "[warn] Could not list pod labels."

banner "Done — no cluster modifications were performed."
