# Kubernetes cluster architecture (reference)

This document summarizes how a **Kubernetes cluster** is structured, how **requests** flow to workloads, and how **DocSync** fits as a **Deployment** + **Service** workload. It complements [`../assignments/A-13-cluster-architecture.md`](../assignments/A-13-cluster-architecture.md).

---

## Cluster architecture (logical)

```text
                    ┌─────────────────────────────────────────┐
                    │            Control plane                 │
                    │  kube-apiserver   etcd                  │
                    │  kube-scheduler   kube-controller-mgr   │
                    └──────────────────┬──────────────────────┘
                                       │ API (HTTPS)
         ┌─────────────────────────────┼─────────────────────────────┐
         ▼                             ▼                             ▼
   ┌─────────────┐             ┌─────────────┐               ┌─────────────┐
   │ Worker node │             │ Worker node │               │ Worker node │
   │ kubelet     │             │ kubelet     │               │ kubelet     │
   │ kube-proxy  │             │ kube-proxy  │               │ kube-proxy  │
   │ containerd  │             │ containerd  │               │ containerd  │
   │  Pods       │             │  Pods       │               │  Pods       │
   └─────────────┘             └─────────────┘               └─────────────┘
```

---

## Request flow (read / write)

1. **User or controller** calls the **API** (`kubectl`, CI, operator) → **`kube-apiserver`**.  
2. **Validation + persistence:** API server writes **desired state** to **etcd** (for most resources).  
3. **Controllers** (e.g. **Deployment controller**) observe desired state and create/update **ReplicaSets** → **Pods**.  
4. **Scheduler** assigns each **Pod** to a **node** that satisfies constraints.  
5. **kubelet** on that node talks to the **container runtime** to start containers.  
6. **kube-proxy** (or **eBPF** dataplane in modern clusters) programs **Service** → **Pod** forwarding rules.

---

## Pod scheduling (short)

| Step | Actor | Action |
|------|--------|--------|
| 1 | **API server** | Pod object created (often via Deployment) |
| 2 | **Scheduler** | Selects node: resources, affinity, taints/tolerations, priority |
| 3 | **kubelet** | Pulls image, creates Pod sandbox, starts containers |
| 4 | **kubelet** | Reports **Ready** when probes succeed |

---

## Control plane responsibilities

| Component | Responsibility |
|-----------|----------------|
| **kube-apiserver** | REST API, authn/z, admission, front door to etcd |
| **etcd** | Distributed key-value store for cluster state |
| **kube-scheduler** | Assigns unscheduled Pods to nodes |
| **kube-controller-manager** | Runs controllers (Deployment, ReplicaSet, Node, etc.) |

> Managed Kubernetes (EKS, GKE, AKS) may hide these processes; **`kubectl`** still targets the same API.

---

## DocSync deployment flow inside Kubernetes

High-level path for this repository (see `k8s/deployment.yaml` and `k8s/service.yaml` — **not** modified by this doc):

```text
  kubectl apply -f k8s/deployment.yaml
          │
          ▼
  API server stores Deployment + Pod template
          │
          ▼
  Deployment controller → ReplicaSet → Pod objects
          │
          ▼
  Scheduler binds each Pod to a node
          │
          ▼
  kubelet pulls ghcr.io/... image and starts DocSync container (:3000)
          │
          ▼
  Readiness/Liveness probes hit /health
          │
          ▼
  Service selects Pods (label app=docsync) and exposes ClusterIP:80 → 3000
```

---

## Networking (one paragraph)

Each **Pod** gets its own **IP** on the **Pod network** (CNI plugin). **Services** provide a **virtual IP** and **stable DNS** that load-balance to **Endpoints** (healthy Pod IPs). **Ingress** (not required for this overview) adds HTTP/S routing from outside the cluster.

---

## HA and scalability (concepts)

| Concept | Meaning |
|---------|---------|
| **HA control plane** | Multiple API servers / etcd members (managed cloud handles this) |
| **Horizontal scale** | More **replicas** in a Deployment; **HPA** adds/removes Pods by metrics |
| **Node scale** | Add worker nodes; scheduler spreads Pods |

---

## Related coursework

- [`../assignments/A-13-cluster-architecture.md`](../assignments/A-13-cluster-architecture.md) — assignment narrative, commands, proofs  

---

*Maintained by the DocSync sprint team.*
