# Assignment A-12 / 4.17 — Introduction to Kubernetes and Cloud-Native Architecture

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Gouri  
**Branch / PR identifier:** `spr12-kubernetes-intro`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.17** (tracker ID: **A-12**) |
| **Module reference** | **Module 5** (or equivalent) — Orchestration fundamentals: clusters, workloads, services, and how DocSync runs as a cloud-native workload |
| **Objective** | Explain **what Kubernetes is** and **why** teams adopt it; contrast **containers vs orchestration**; map DocSync’s **Source → Image → Registry → Kubernetes** path; relate **GHCR images** to **`Deployment`** / **`Service`** manifests in this repo; preview **`kubectl`** commands used to observe a cluster. |

---

## What is Kubernetes?

**Kubernetes (K8s)** is an **open-source container orchestration platform**. It continuously **reconciles** the **desired state** you declare (YAML manifests, Helm charts, GitOps repos) against the **actual state** of running workloads on a **cluster** of nodes.

| Term | Meaning |
|------|---------|
| **Cluster** | Control plane + worker nodes running the container runtime |
| **Pod** | Smallest deployable unit (one or more containers sharing network/storage namespaces) |
| **Controller** | e.g. **Deployment** — maintains replica count and rollout strategy |
| **Service** | Stable network abstraction to reach a set of Pods |

---

## Why Kubernetes is used

| Driver | Benefit |
|--------|---------|
| **Declarative operations** | Describe **what** you want; controllers converge |
| **Portability** | Same API across clouds and on-prem (with caveats for integrations) |
| **Automation** | Scheduling, restarts, rollouts, autoscaling hooks |
| **Ecosystem** | Ingress, service mesh, operators, observability integrations |

---

## Cloud-native architecture overview

**Cloud-native** systems are built to **exploit cloud delivery**: microservices or modular services, **API-driven** automation, **containers**, **orchestration**, **CI/CD**, and **observability**. Kubernetes is often the **control plane** for running those containerized services at scale.

```text
  Developers ──► Git / CI ──► Registry ──► Kubernetes ──► Users
                  │              │              │
                  │              │         Ingress / Service
                  │              │         Deployments / HPAs
                  └──────────────┴──────────── Observability
```

---

## Problems Kubernetes solves

| Without orchestration | With Kubernetes |
|------------------------|-----------------|
| Manual placement on VMs | **Scheduler** assigns Pods to healthy nodes |
| Snowflake servers | **Desired state** + identical Pod specs |
| Manual failover | **ReplicaSet** / Deployment replaces failed Pods |
| Static IPs tied to machines | **Services** + DNS for stable access patterns |

---

## Containers vs orchestration

| Layer | Responsibility |
|-------|----------------|
| **Container (Docker, etc.)** | Package **one process tree** with filesystem and config |
| **Orchestration (Kubernetes)** | **Schedules** many containers, **wires** networking, **enforces** replicas, **rolls** updates |

Docker answers: “**How do I build and run this image?**”  
Kubernetes answers: “**How do I run N copies, expose them, upgrade them safely, and heal failures?**”

---

## Kubernetes role in this DocSync project

DocSync is packaged as a **container image** (see repository `Dockerfile`) and described for Kubernetes using:

| Artifact | Purpose |
|----------|---------|
| `k8s/deployment.yaml` | **Replicas**, update strategy, probes, resource requests/limits, **image** reference |
| `k8s/service.yaml` | **ClusterIP** access to the DocSync Pods on port 80 → container port 3000 |

CI/CD (GitHub Actions) builds and pushes images to **GHCR**; the cluster **pulls** that image when the Deployment is applied.

---

## Source → Image → Registry → Kubernetes flow

```text
  Git (source)
      │
      ▼
  CI: docker build ──► immutable image
      │
      ▼
  GHCR (registry)
      │
      ▼
  kubectl apply / CD pipeline
      │
      ▼
  Kubernetes: Deployment creates Pods
      │
      ▼
  Service routes traffic to ready Pods
```

---

## How Docker image from GHCR will be deployed to Kubernetes

1. **Image published** to `ghcr.io/<org>/<repo>:<tag>@sha256:…` (digest preferred for prod).  
2. **`Deployment`** `spec.template.spec.containers[].image` references that URI (see `k8s/deployment.yaml`).  
3. **kubelet** on each node **pulls** the image (subject to `imagePullSecrets` if private).  
4. **Pods** start; **readiness** / **liveness** probes hit DocSync **`/health`**.  
5. **Service** selects Pods with matching labels and forwards traffic.

> Align manifest image with the **exact** repository and tag your registry publishes; update via PR or GitOps when promoting releases.

---

## Benefits: scaling, self-healing, rollouts, service discovery

| Capability | DocSync angle |
|------------|----------------|
| **Scaling** | Increase `spec.replicas` or add **HPA** (future work) |
| **Self-healing** | Failed Pods replaced; probes remove bad instances from load |
| **Rollouts** | **RollingUpdate** strategy in `Deployment` for zero-downtime-ish upgrades |
| **Service discovery** | **Cluster DNS** resolves `Service` names; **labels** connect Service ↔ Pods |

---

## Commands used

> Requires a configured kubeconfig (`~/.kube/config`) and cluster access. Outputs vary by environment.

### `kubectl version --client`

```bash
kubectl version --client
```

**Expected:** `Client Version` with `GitVersion` (e.g. `v1.29.x`).

---

### `kubectl cluster-info`

```bash
kubectl cluster-info
```

**Expected:** control plane URL(s); errors if **no context** or **unreachable** API.

---

### `kubectl get nodes`

```bash
kubectl get nodes
```

**Expected:** `NAME`, `STATUS` **Ready** for healthy nodes.

---

### `kubectl get pods`

```bash
kubectl get pods -A
kubectl get pods -l app=docsync
```

**Expected:** Pod list; DocSync Pods show **Running** when deployed.

---

### `kubectl get deployments`

```bash
kubectl get deployments
kubectl get deployment docsync
```

**Expected:** `docsync` Deployment with desired/ready counts.

---

### `kubectl get svc`

```bash
kubectl get svc
kubectl get svc docsync
```

**Expected:** `ClusterIP` (or other type) for `docsync` **Service**.

---

## Expected outputs (summary)

| Command | Healthy signal |
|---------|----------------|
| `kubectl version --client` | Client version prints |
| `kubectl cluster-info` | API server endpoint reachable |
| `kubectl get nodes` | Nodes **Ready** |
| `kubectl get pods` | DocSync Pods **Running** / **READY** |
| `kubectl get deployments` | `READY` matches desired replicas |
| `kubectl get svc` | Service has **CLUSTER-IP** and **PORT(S)** |

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `kubectl version --client` | `docs/proofs/4.17-kubectl-version.png` |
| 2 | `kubectl cluster-info` | `docs/proofs/4.17-cluster-info.png` |
| 3 | `kubectl get nodes` | `docs/proofs/4.17-get-nodes.png` |
| 4 | Architecture diagram or this assignment in IDE / printed PDF | `docs/proofs/4.17-k8s-architecture.png` |

---

## Validation checklist

- [ ] Can define **Kubernetes** and name **three** core objects (e.g. Pod, Deployment, Service)  
- [ ] Can trace DocSync from **GHCR image** to **Pod** using repo manifests  
- [ ] Ran **`kubectl version --client`** successfully  
- [ ] Ran **`kubectl cluster-info`** and **`kubectl get nodes`** (or captured “no cluster” blocker for coursework notes)  
- [ ] Captured proofs per `docs/proofs/README.md` (Assignment **4.17**)  
- [ ] Opened PR **`spr12-kubernetes-intro`** for review  

---

## Learning outcome

After **Assignment 4.17 / A-12**, you can:

- Explain **why** orchestration exists on top of containers.  
- Describe DocSync’s place in a **cloud-native** delivery pipeline.  
- Use baseline **`kubectl`** read commands to **observe** cluster health and workloads.  

---

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)  
- [CNCF Cloud Native Definition](https://github.com/cncf/toc/blob/main/DEFINITION.md)  
- Repository: `k8s/deployment.yaml`, `k8s/service.yaml`, `README.md`  
