#!/usr/bin/env bash
# DocSync — read-only Deployment / Pod / probe diagnostics (Sprint #3 · PR18)
# Does not apply, restart, or port-forward (port-forward blocks; run manually).

set -uo pipefail

DEPLOY="${DEPLOY:-docsync}"
LABEL_SELECTOR="${LABEL_SELECTOR:-app=docsync}"

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

banner "Rollout status (non-blocking)"

if kubectl get deployment "$DEPLOY" &>/dev/null; then
  kubectl rollout status "deployment/$DEPLOY" --timeout=20s 2>&1 || true
else
  echo "[info] Deployment '$DEPLOY' not found in current namespace."
fi

banner "Pods ($LABEL_SELECTOR)"

kubectl get pods -l "$LABEL_SELECTOR" -o wide 2>&1 || echo "[warn] kubectl get pods failed."

banner "Describe deployment ($DEPLOY)"

if kubectl get deployment "$DEPLOY" &>/dev/null; then
  kubectl describe deployment "$DEPLOY" 2>&1
else
  echo "[info] Skipping describe — deployment not found."
fi

banner "Pod lines mentioning probes / health (from describe)"

pods=$(kubectl get pods -l "$LABEL_SELECTOR" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
if [[ -z "${pods// }" ]]; then
  echo "(no Pods matched $LABEL_SELECTOR)"
else
  for po in $pods; do
    echo "--- $po ---"
    if kubectl get pod "$po" &>/dev/null; then
      kubectl describe pod "$po" 2>/dev/null | grep -iE 'liveness|readiness|unhealthy|probe|/health|back-off|killing|started' || echo "(no probe-related lines matched — see Events tail below)"
      echo "... Events tail (describe pod):"
      kubectl describe pod "$po" 2>/dev/null | tail -n 18 || true
    fi
  done
fi

banner "Test /health via port-forward (run manually)"

cat <<'EOF'
# Terminal A — forward Service port 80 to local 3000 (DocSync listens on 3000 inside the Pod; Service maps 80→3000):
kubectl port-forward svc/docsync-service 3000:80

# Terminal B:
curl -sS -i http://localhost:3000/health

# Optional — logs while probes run:
kubectl logs -f deployment/docsync
EOF

banner "Done — no apply/delete/restart/port-forward was executed by this script."
