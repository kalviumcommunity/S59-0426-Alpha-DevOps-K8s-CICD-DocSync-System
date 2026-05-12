# Assignment A-13 / 4.18 — Kubernetes Cluster Architecture and Control Plane

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Gouri  
**Branch / PR identifier:** `spr13-cluster-architecture`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.18** (tracker ID: **A-13**) |
| **Module reference** | **Module 5** (or equivalent) — Cluster components: control plane, nodes, runtime, and how traffic and state flow through the system |
| **Objective** | Explain **cluster** and **control plane** architecture; describe **worker** components (**kubelet**, **kube-proxy**, **runtime**); map **API → etcd → controllers → scheduler → kubelet → Pod**; relate networking and **HA/scalability** concepts to how **DocSync** runs on Kubernetes. |

**Deep-dive reference:** [`docs/architecture/K8S_CLUSTER_ARCHITECTURE.md`](../architecture/K8S_CLUSTER_ARCHITECTURE.md)

---

## Kubernetes cluster overview

A **cluster** is a set of **machines** (physical or virtual) divided into:

| Tier | Role |
|------|------|
| **Control plane** | Exposes the API, stores state, schedules work, runs controllers |
| **Worker nodes** | Run **kubelet**, **kube-proxy**, **container runtime**, and **Pods** |

Administrators and CI systems talk to the **API server**; nodes execute **desired state**.

---

## Control plane explanation

The **control plane** implements the Kubernetes API and reconciliation loops. It is **not** where application containers run (except for special cases like static pods on bootstrap nodes).

---

## Worker node explanation

A **worker node** is a host where:

- **kubelet** ensures Pods assigned to this node are running and healthy.  
- **kube-proxy** (or a compatible dataplane) implements **Service** routing.  
- **Container runtime** (e.g. **containerd**) pulls images and runs containers.

---

## kube-apiserver

| Aspect | Detail |
|--------|--------|
| **Role** | Single **front door** for the Kubernetes API (REST) |
| **Responsibilities** | Authentication, authorization, admission, validation, persistence coordination |
| **Clients** | `kubectl`, controllers, operators, CI/CD |

---

## etcd

| Aspect | Detail |
|--------|--------|
| **Role** | Strongly consistent **store** for cluster configuration and most resource state |
| **Why it matters** | Enables watch-based controllers; loss/corruption of etcd is catastrophic |

---

## scheduler

**kube-scheduler** assigns **unscheduled** Pods to nodes by scoring feasible nodes against **resources**, **affinity/anti-affinity**, **taints/tolerations**, **priorities**, and **topology**.

---

## controller-manager

**kube-controller-manager** runs **controllers** (control loops), including:

- **Deployment** / **ReplicaSet** — desired replica count  
- **Node** — node health bookkeeping  
- **ServiceAccount** token (legacy paths), and many more  

Each controller **watches** API objects and **mutates** state toward the declared spec.

---

## kubelet

| Aspect | Detail |
|--------|--------|
| **Role** | **Node agent** — reports node health, runs Pod lifecycle on **this** node |
| **Interacts with** | API server, container runtime, cgroups/namespaces |

---

## kube-proxy

| Aspect | Detail |
|--------|--------|
| **Role** | Programs **Service** → **Pod** forwarding (iptables/IPVS or eBPF depending on implementation) |
| **User impact** | Stable **ClusterIP** / **NodePort** behavior for workloads like DocSync |

---

## Container runtime

Examples: **containerd**, **CRI-O**. The **kubelet** uses the **CRI** (Container Runtime Interface) to:

- Pull images (e.g. DocSync from **GHCR**)  
- Create Pod sandboxes and containers  
- Report status back to the API server  

---

## How Pods run inside nodes

1. **Pod** spec lands on a node (bound by scheduler).  
2. **kubelet** instructs **runtime** to create pause/init/app containers.  
3. **Networking** plugin attaches Pod to cluster network.  
4. **Probes** (readiness/liveness) gate traffic and restart policy.

DocSync’s `Deployment` defines **Pod template** (labels, image, ports, probes) in `k8s/deployment.yaml`.

---

## Networking overview

- **Pod network:** each Pod IP (CNI).  
- **Service:** stable virtual IP + DNS + kube-proxy dataplane.  
- **Ingress / Gateway:** north-south HTTP(S) (optional for DocSync beyond `Service` + port-forward).

---

## Cluster communication flow

```text
  kubectl / CI
       │
       ▼
  kube-apiserver ◄────► etcd
       │
       ├──► controllers (desired state)
       │
       └──► scheduler (Pod → node binding)
                │
                ▼
            kubelet ──► runtime ──► DocSync container
                │
                ▼
            kube-proxy ──► Service endpoints
```

---

## How this architecture supports the DocSync project

| Need | Mechanism |
|------|-----------|
| **Repeatable rollout** | `Deployment` + versioned **image** from GHCR |
| **Health-aware traffic** | **Readiness** / **liveness** on `/health` |
| **In-cluster access** | `Service` **ClusterIP** to Pods |
| **Resilience** | Multiple **replicas**, rolling updates, self-healing |

---

## High availability concepts

| Idea | Practice |
|------|----------|
| **Control plane HA** | Multiple API/etcd members (often cloud-managed) |
| **Workload HA** | **replicas > 1**, **PodDisruptionBudgets** (advanced), multi-AZ node pools |
| **etcd backup** | Regular snapshots in production |

---

## Scalability concepts

| Axis | Tooling |
|------|---------|
| **More Pods** | `spec.replicas`, **HPA** |
| **More nodes** | cluster autoscaler (cloud) |
| **Bigger Pods** | requests/limits tuning (see existing `k8s/deployment.yaml` resources) |

---

## Commands used

> Outputs depend on cluster version and permissions. `kubectl get componentstatuses` is **deprecated/removed** on many modern clusters — see note below.

### `kubectl cluster-info`

```bash
kubectl cluster-info
```

**Expected:** Kubernetes control plane URL; DNS addon endpoints if installed.

---

### `kubectl get nodes`

```bash
kubectl get nodes -o wide
```

**Expected:** `Ready` nodes with roles, versions, internal IPs.

---

### `kubectl describe node`

```bash
kubectl describe node <node-name>
```

**Expected:** Capacity/allocatable, conditions (`Ready`, `MemoryPressure`, …), Pod summary, events.

---

### `kubectl get componentstatuses` (legacy)

```bash
kubectl get componentstatuses 2>/dev/null || echo "Not available on this cluster version (deprecated/removed)."
```

**Note:** On Kubernetes **1.19+** this API is often **absent**. Prefer health checks such as:

```bash
kubectl get --raw='/readyz?verbose'
kubectl get --raw='/livez?verbose'
```

---

### `kubectl get pods -A`

```bash
kubectl get pods -A
```

**Expected:** all-namespaces Pod list; system namespaces (`kube-system`, etc.) plus application namespaces.

---

## Expected outputs (summary)

| Command | Healthy signal |
|---------|------------------|
| `cluster-info` | API reachable |
| `get nodes` | `Ready` |
| `describe node` | Conditions without persistent `NotReady` |
| `get pods -A` | System Pods running; DocSync Pods `Running` when deployed |

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `kubectl get nodes` | `docs/proofs/4.18-get-nodes.png` |
| 2 | `kubectl describe node …` | `docs/proofs/4.18-describe-node.png` |
| 3 | Architecture (this doc, `K8S_CLUSTER_ARCHITECTURE.md`, or slides) | `docs/proofs/4.18-architecture.png` |
| 4 | `kubectl get pods -A` | `docs/proofs/4.18-get-pods-A.png` |

---

## Validation checklist

- [ ] Can sketch **control plane vs worker** and label major components  
- [ ] Can narrate **scheduler** vs **kubelet** responsibilities  
- [ ] Ran **`kubectl get nodes`** and **`kubectl describe node`** (or documented cluster access blocker)  
- [ ] Ran **`kubectl get pods -A`**  
- [ ] Read [`docs/architecture/K8S_CLUSTER_ARCHITECTURE.md`](../architecture/K8S_CLUSTER_ARCHITECTURE.md)  
- [ ] Captured proofs per `docs/proofs/README.md` (Assignment **4.18**)  
- [ ] Opened PR **`spr13-cluster-architecture`** for review  

---

## Learning outcome

After **Assignment 4.18 / A-13**, you can:

- Trace a **`kubectl apply`** through the **control plane** to **running Pods**.  
- Explain **kubelet**, **runtime**, and **kube-proxy** roles on a **node**.  
- Connect **cluster architecture** to **DocSync’s** `Deployment` + `Service` model.  

---

## References

- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)  
- [`docs/architecture/K8S_CLUSTER_ARCHITECTURE.md`](../architecture/K8S_CLUSTER_ARCHITECTURE.md)  
