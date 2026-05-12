#!/usr/bin/env bash
# DocSync — read-only Service / Endpoints inspection (Sprint #3 · PR17)
# Does not apply, delete, or port-forward (port-forward blocks; run manually).

set -uo pipefail

SVC_CLUSTERIP="${SVC_CLUSTERIP:-docsync-service}"
SVC_NODEPORT="${SVC_NODEPORT:-docsync-nodeport}"

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

banner "Services (current namespace)"

kubectl get svc -o wide 2>&1 || echo "[warn] kubectl get svc failed."

banner "Describe ClusterIP service (${SVC_CLUSTERIP})"

if kubectl get svc "$SVC_CLUSTERIP" &>/dev/null; then
  kubectl describe svc "$SVC_CLUSTERIP" 2>&1
else
  echo "[info] Service '$SVC_CLUSTERIP' not found in current namespace."
fi

banner "Endpoints (Pod IPs behind the Services)"

for ep in "$SVC_CLUSTERIP" "$SVC_NODEPORT"; do
  if kubectl get svc "$ep" &>/dev/null; then
    echo "--- endpoints/$ep ---"
    kubectl get endpoints "$ep" -o wide 2>&1 || kubectl get endpoints "$ep" 2>&1 || true
  else
    echo "[info] Service '$ep' not present — skipping endpoints."
  fi
done

banner "Port-forward testing (run manually in a second terminal)"

cat <<'EOF'
# ClusterIP — local laptop reaches the Service via kube-apiserver proxy:
kubectl port-forward svc/docsync-service 3000:80
# then:
curl -sS http://localhost:3000/health

# NodePort — after: kubectl get svc docsync-nodeport
# visit http://<node-ip>:<NODEPORT>/health from a machine that can reach the node (path may vary; DocSync serves /health on the app port).
EOF

banner "Done — no apply/delete/port-forward was executed by this script."
