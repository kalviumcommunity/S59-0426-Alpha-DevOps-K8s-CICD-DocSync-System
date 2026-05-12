# Assignment A-14 / 4.19 — Setting Up a Local Kubernetes Cluster (kind / Minikube / k3s)

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Gouri  
**Branch / PR identifier:** `spr14-local-k8s-cluster`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.19** (tracker ID: **A-14**) |
| **Module reference** | **Module 5** (or equivalent) — Local clusters for fast feedback: **kind**, **Minikube**, **k3s**, and **`kubectl`** context hygiene |
| **Objective** | Compare **kind**, **Minikube**, and **k3s**; justify a **preferred** local stack for DocSync; document **create → verify → delete** workflow; configure **`kubectl`**; capture **proofs**; use the read-only helper **`scripts/k8s-local-cluster-check.sh`** for repeatable diagnostics. |

---

## Why local Kubernetes clusters are needed

| Reason | Benefit |
|--------|---------|
| **Cost & speed** | Free iteration without cloud spend or slow provisioning |
| **Safety** | Break things locally before production namespaces |
| **CI parity** | Many pipelines use **kind** for conformance/smoke tests |
| **Learning** | Practice `kubectl`, manifests, and debugging with resettable clusters |

---

## kind overview

**kind** (Kubernetes **in** Docker) runs Kubernetes **control plane + nodes as containers** on a single Docker host.

| Pros | Cons |
|------|------|
| Fast create/destroy; great for CI | Networking/load-balancer differs from “real” cloud LB |
| Multi-node clusters supported | Heavy RAM/CPU on laptops |

**Typical create:**

```bash
kind create cluster --name docsync-cluster
```

---

## Minikube overview

**Minikube** provisions a local Kubernetes VM or container (driver-dependent) with addons and **`minikube`** CLI helpers.

| Pros | Cons |
|------|------|
| Mature tutorials, `minikube service` | Slightly more “magic” than kind for some drivers |
| Addons (ingress, metrics) | Resource footprint varies by driver |

---

## k3s overview

**k3s** is a **minimal certified Kubernetes** distribution by Rancher/SUSE—popular for **edge** and **single-node** servers.

| Pros | Cons |
|------|------|
| Small binary, quick start | Less “all-in-docker” than kind for laptop sandboxes |
| Great for systemd hosts / IoT | Different install path than Docker-only devs |

---

## Comparison: kind vs Minikube vs k3s

| Dimension | **kind** | **Minikube** | **k3s** |
|-----------|----------|----------------|---------|
| **Primary host** | Docker | VM/container (driver-specific) | Linux host (often) |
| **Startup speed** | Very fast | Medium | Fast on Linux |
| **CI usage** | Extremely common | Common | Common on servers |
| **Multi-node** | Yes | Yes (advanced) | Yes (k3d wraps k3s in Docker) |

---

## Preferred approach for this project (and why)

**Recommendation: `kind`** for DocSync local development and teaching alignment with **Docker-first** workflows:

- DocSync already centers on **Docker** images and **GHCR**; **kind** reuses Docker as the node runtime.  
- **GitHub Actions** and many upstream examples standardize on **kind** for lightweight Kubernetes tests.  
- **Fast reset** (`kind delete cluster`) matches sprint PR workflows.

**Minikube** remains an excellent alternative if your course mandates it or you rely on **driver-specific** integrations. **k3s** shines when emulating **edge** or running on a **Linux VM** rather than only Docker Desktop.

---

## Cluster setup workflow (kind example)

1. Install **Docker**, **kubectl**, **kind**.  
2. `kind create cluster --name docsync-cluster`  
3. `kubectl cluster-info` && `kubectl get nodes`  
4. Apply DocSync manifests (`kubectl apply -f k8s/…`) in a later assignment **without** editing them here.  
5. When finished: `kind delete cluster --name docsync-cluster`

---

## kubectl configuration

| Task | Command |
|------|---------|
| **List contexts** | `kubectl config get-contexts` |
| **Current context** | `kubectl config current-context` |
| **Switch context** | `kubectl config use-context <name>` |

**kubeconfig** path defaults to `~/.kube/config`; avoid committing it.

---

## Node verification

```bash
kubectl get nodes -o wide
kubectl describe node <node-name>
```

**Expected:** `STATUS` **Ready** for each node in a healthy local cluster.

---

## Cluster troubleshooting basics

| Symptom | Check |
|---------|--------|
| `Unable to connect to the server` | Docker running? `kind get clusters`? correct **context**? |
| `nodes NotReady` | Resources, kubelet logs inside kind node container |
| `ImagePullBackOff` | Registry auth (`imagePullSecrets`) or wrong image name |
| Wrong cluster targeted | `kubectl config current-context` |

---

## How local Kubernetes validates deployments before production

| Practice | Outcome |
|----------|---------|
| Apply same **YAML** as prod (with image/tag overrides in later steps) | Catch schema/label mistakes early |
| Exercise **probes** and **Service** wiring | Reduce first-day production surprises |
| Rehearse **rollouts** / `kubectl rollout status` | Build operational muscle memory |

---

## Commands used

### `kind create cluster --name docsync-cluster`

**Expected:** cluster provisioning logs; kubeconfig updated with a new context.

---

### `kubectl cluster-info`

**Expected:** Kubernetes control plane URL is printed.

---

### `kubectl get nodes`

**Expected:** one or more nodes in **Ready** state.

---

### `kubectl get pods -A`

**Expected:** `kube-system` pods plus your workload namespaces once applied.

---

### `kubectl config get-contexts`

**Expected:** table with `CURRENT`, `CLUSTER`, `AUTHINFO`, `NAMESPACE`.

---

### `kubectl config current-context`

**Expected:** single context name string (e.g. `kind-docsync-cluster`).

---

### `kind delete cluster --name docsync-cluster`

**Expected:** cluster torn down; context removed or stale (clean kubeconfig if needed).

---

### Read-only check script

```bash
chmod +x scripts/k8s-local-cluster-check.sh
./scripts/k8s-local-cluster-check.sh
```

**Expected:** prerequisite summary, contexts, `cluster-info`, `nodes`, `pods` (or graceful warnings).

---

## Expected outputs (summary)

| Step | Pass criteria |
|------|----------------|
| `kind create …` | Context exists; `kubectl get nodes` works |
| `cluster-info` | API responds |
| `get pods -A` | CoreDNS / kube-proxy pods running |
| `kind delete …` | `kind get clusters` no longer lists `docsync-cluster` |

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `kind create cluster …` success | `docs/proofs/4.19-kind-create.png` |
| 2 | `kubectl cluster-info` | `docs/proofs/4.19-cluster-info.png` |
| 3 | `kubectl get nodes` | `docs/proofs/4.19-get-nodes.png` |
| 4 | `kubectl get pods -A` | `docs/proofs/4.19-get-pods-A.png` |
| 5 | `kubectl config current-context` / `get-contexts` | `docs/proofs/4.19-context.png` |
| 6 | `./scripts/k8s-local-cluster-check.sh` | `docs/proofs/4.19-script-check.png` |

---

## Validation checklist

- [ ] Compared **kind / Minikube / k3s** and recorded **preference** for DocSync  
- [ ] Created and deleted a **local** cluster (or captured instructor-provided cluster + context)  
- [ ] Verified **`kubectl`** context and **nodes**  
- [ ] Ran **`scripts/k8s-local-cluster-check.sh`** (safe, repeatable)  
- [ ] Captured proofs per `docs/proofs/README.md` (Assignment **4.19**)  
- [ ] Opened PR **`spr14-local-k8s-cluster`** for review  

---

## Learning outcome

After **Assignment 4.19 / A-14**, you can:

- Choose a **local Kubernetes** tool appropriate for Docker-centric coursework.  
- Manage **kubeconfig contexts** safely.  
- **Validate** cluster health before applying application manifests.  

---

## References

- [kind documentation](https://kind.sigs.k8s.io/)  
- [Minikube documentation](https://minikube.sigs.k8s.io/docs/)  
- [k3s documentation](https://docs.k3s.io/)  
