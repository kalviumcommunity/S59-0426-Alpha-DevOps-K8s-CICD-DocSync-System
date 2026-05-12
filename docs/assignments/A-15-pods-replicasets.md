# Assignment A-15 / 4.20 — Understanding Kubernetes Objects: Pods and ReplicaSets

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Gouri  
**Branch / PR identifier:** `spr15-pods-replicasets`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.20** (tracker ID: **A-15**) |
| **Module reference** | **Module 5–6** (or equivalent) — Core workload API: **Pods**, **ReplicaSets**, labels/selectors, and desired-state reconciliation |
| **Objective** | Explain **Pods** and **ReplicaSets**; relate them to **DocSync**; practice **apply / get / describe / delete**; observe **self-healing**; capture proofs; use the read-only script **`scripts/k8s-pod-check.sh`**. |

---

## What is a Pod

A **Pod** is the smallest deployable unit in Kubernetes: one or more **containers** that share network (IP, ports), IPC options, and storage volumes. The kubelet runs Pods on a **Node**.

| Aspect | Detail |
|--------|--------|
| **Scheduling** | Assigned to one node at a time |
| **Identity** | Stable **name** in a namespace; **UID** is globally unique |
| **Networking** | Containers in the same Pod reach each other on `localhost` with distinct ports |

---

## Pod lifecycle

| Phase | Meaning |
|-------|---------|
| **Pending** | Accepted by API; images pulling or scheduling incomplete |
| **Running** | At least one container running or starting |
| **Succeeded** | All containers terminated successfully (batch-style) |
| **Failed** | At least one container terminated with failure |
| **Unknown** | Node communication lost |

---

## Single-container vs multi-container Pods

| Model | When to use | DocSync relevance |
|-------|-------------|-------------------|
| **Single-container** | Typical microservice | DocSync API runs as **one** main Node process per replica |
| **Multi-container** | Sidecars (logging, mesh, config sync) | Future: observability or proxy sidecars—not required for this assignment |

---

## What is a ReplicaSet

A **ReplicaSet** (`apps/v1`) maintains a **stable set** of running Pods matching a **label selector**. The controller reconciles **observed** vs **desired** replica count.

---

## Why ReplicaSets are important

| Benefit | Explanation |
|---------|-------------|
| **Availability** | Multiple replicas survive single-node or single-Pod loss |
| **Homogeneity** | Same pod template for every replica |
| **Foundation** | **Deployments** manage ReplicaSets for rolling updates |

---

## Relationship between Pods and ReplicaSets

```text
ReplicaSet (desired replicas = N)
    └── Pod (owned via controller reference + selector match)
    └── Pod
    └── …
```

- The ReplicaSet **selector** must match the **Pod template** labels.  
- Pods **created** by the ReplicaSet carry an **ownerReference** linking back to that ReplicaSet.

---

## Self-healing behavior

If a Pod managed by a ReplicaSet **terminates** or is **deleted**, the controller **creates a replacement** to restore the desired count—**as long as** the node is healthy and scheduling succeeds.

**Classroom demo:** `kubectl delete pod <pod-name>` on a ReplicaSet-owned Pod; a new Pod name appears with the same labels.

---

## Scaling concepts

| Action | Mechanism |
|--------|-----------|
| **Scale out** | Increase `spec.replicas` (ReplicaSet or Deployment) |
| **Scale in** | Decrease `spec.replicas`; controller terminates excess Pods |

> **Note:** In production, prefer **Deployments** for versioned rollouts; ReplicaSets alone are common for learning and for the **ReplicaSet** object layer under Deployments.

---

## How Pods and ReplicaSets apply to the DocSync project

| Object | DocSync usage |
|--------|----------------|
| **Pod** | One DocSync **container** listening on **port 3000** (HTTP + `/health`) |
| **ReplicaSet** (learning manifest) | Holds **≥ 2** replicas of the same DocSync image for HA practice |
| **Deployment** (existing `k8s/deployment.yaml`) | Higher-level rollout over ReplicaSets—**do not delete** for this exercise unless your instructor directs cleanup |

The manifests in this assignment (`k8s/pod.yaml`, `k8s/replicaset.yaml`) use **distinct labels** from the repo **Deployment** so a learner can apply them **without** selector clashes against `app: docsync` production-style manifests.

---

## Kubernetes object hierarchy overview

```text
Namespace
  ├── Pod (standalone OR owned)
  ├── ReplicaSet
  │     └── Pod (owned)
  └── Deployment (typical production path)
        └── ReplicaSet (per revision)
              └── Pod
```

---

## Manifests in this repository

| File | Purpose |
|------|---------|
| [`k8s/pod.yaml`](../k8s/pod.yaml) | Single **standalone** DocSync Pod (learning) |
| [`k8s/replicaset.yaml`](../k8s/replicaset.yaml) | DocSync **ReplicaSet** with **2** replicas (learning) |

---

## Commands used

Apply the learning objects (default namespace unless you set `-n`):

```bash
kubectl apply -f k8s/pod.yaml
kubectl apply -f k8s/replicaset.yaml
```

Inspect workloads:

```bash
kubectl get pods
kubectl get rs
kubectl describe pod <pod-name>
```

Demonstrate self-healing (pick a Pod **owned by the ReplicaSet** from `kubectl get pods`):

```bash
kubectl delete pod <pod-name>
kubectl get pods -w
```

Read-only diagnostics:

```bash
chmod +x scripts/k8s-pod-check.sh
./scripts/k8s-pod-check.sh
```

---

## Expected outputs

| Command | Pass criteria |
|---------|----------------|
| `kubectl apply -f k8s/pod.yaml` | `created` or `configured` |
| `kubectl apply -f k8s/replicaset.yaml` | ReplicaSet created; **2** Pods become **Running** (image pull permitting) |
| `kubectl get pods` | Lists `docsync-standalone-learning` and ReplicaSet pods (names vary) |
| `kubectl get rs` | `DESIRED` = `CURRENT` = `READY` = 2 for the learning ReplicaSet |
| `kubectl describe pod …` | Events show scheduling, pulls, probe results |
| `kubectl delete pod …` (RS-owned) | New Pod recreated; count returns to desired |

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `k8s/pod.yaml` in editor or `cat` | `docs/proofs/4.20-pod-yaml.png` |
| 2 | `k8s/replicaset.yaml` | `docs/proofs/4.20-replicaset-yaml.png` |
| 3 | `kubectl get pods` | `docs/proofs/4.20-get-pods.png` |
| 4 | `kubectl get rs` | `docs/proofs/4.20-get-rs.png` |
| 5 | Delete RS Pod + recreation (`get pods -w` or before/after) | `docs/proofs/4.20-self-heal.png` |
| 6 | `./scripts/k8s-pod-check.sh` | `docs/proofs/4.20-script-pod-check.png` |

---

## Validation checklist

- [ ] Read **Pod** vs **ReplicaSet** responsibilities and **selector** rules  
- [ ] Applied **`k8s/pod.yaml`** and **`k8s/replicaset.yaml`** in a test namespace or cluster  
- [ ] Verified **labels** align between ReplicaSet `selector` and Pod template  
- [ ] Observed **self-healing** after deleting a ReplicaSet-managed Pod  
- [ ] Ran **`scripts/k8s-pod-check.sh`** (read-only)  
- [ ] Captured proofs per **`docs/proofs/README.md`** (Assignment **4.20**)  
- [ ] Opened PR **`spr15-pods-replicasets`** for review  

---

## Learning outcome

After **Assignment 4.20 / A-15**, you can:

- Define **Pods** and **ReplicaSets** and explain **owner relationships**  
- Interpret **labels/selectors** and why they must stay consistent  
- Predict **self-healing** when Pods disappear  
- Relate these primitives to DocSync’s **Deployment**-based path in later work  

---

## References

- [Kubernetes Pods](https://kubernetes.io/docs/concepts/workloads/pods/)  
- [ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)  
