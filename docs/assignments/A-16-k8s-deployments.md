# Assignment A-16 / 4.21 — Creating and Managing Deployments

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Gouri  
**Branch / PR identifier:** `spr16-k8s-deployments`  

**Prerequisite context:** [A-15 / 4.20 — Pods and ReplicaSets](A-15-pods-replicasets.md) introduced low-level workload objects; this assignment layers **Deployments** for production-style lifecycle management.

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.21** (tracker ID: **A-16**) |
| **Module reference** | **Module 6** (or equivalent) — `apps/v1` **Deployment**: desired state, **ReplicaSets**, **rolling updates**, and **rollbacks** |
| **Objective** | Explain **Deployments** vs raw Pods; map **Deployment → ReplicaSet → Pod**; practice **rollout** commands; relate manifests to **DocSync**; capture proofs; use **`scripts/k8s-deployment-check.sh`** for read-only inspection. |

---

## What is a Deployment

A **Deployment** is a Kubernetes controller that declares **how many** Pod replicas should run and **how** to change them over time. It owns one or more **ReplicaSets** (one per revision) and reconciles **observed** state toward **spec** (image, env, probes, replica count).

---

## Why Deployments are preferred over raw Pods

| Raw Pod | Deployment |
|---------|----------------|
| No built-in rollout of a new image | **RollingUpdate** replaces Pods gradually |
| Manual recreation after failure | Controller maintains **desired replicas** |
| No revision history | **`kubectl rollout history`** tracks revisions |

---

## Relationship between Deployments, ReplicaSets, and Pods

```text
Deployment (docsync)
  └── ReplicaSet (revision N, hash label)
        └── Pod
        └── Pod
  └── ReplicaSet (revision N-1)  ← scaled to 0 after successful rollout
```

- **Deployment** `spec.selector` must match **Pod template** labels.  
- Each template change creates a **new ReplicaSet**; the Deployment scales old/new RS during rollout.

---

## Rolling updates

| Setting | Role in DocSync (`k8s/deployment.yaml`) |
|---------|-------------------------------------------|
| `strategy.type: RollingUpdate` | Replace Pods incrementally |
| `maxUnavailable` | Cap simultaneous downtime |
| `maxSurge` | Temporary extra Pods during rollout |

---

## Rollbacks

| Command | Use |
|---------|-----|
| `kubectl rollout history deployment/docsync` | List revisions |
| `kubectl rollout undo deployment/docsync` | Roll back to previous revision *(use only in clusters where you own the namespace)* |

> **Note:** This assignment emphasizes **inspection**; undo is powerful—confirm with your instructor before running in shared clusters.

---

## Desired state management

The API server stores **desired** configuration (`spec`); controllers continuously **reconcile** running Pods to match **selector + template**. Drift (deleted Pod, failed node) is corrected unless blocked (e.g. `ImagePullBackOff`).

---

## Scaling concepts

| Action | Command / field |
|--------|-----------------|
| **Scale horizontally** | `kubectl scale deployment/docsync --replicas=3` or edit `spec.replicas` |
| **Autoscale (future)** | HorizontalPodAutoscaler (out of scope for 4.21) |

---

## Deployment lifecycle

| Stage | What happens |
|-------|----------------|
| **Create** | Deployment controller creates ReplicaSet + Pods |
| **Progressing** | New Pods become **Ready** per readiness probes |
| **Available** | `minReadySeconds` / readiness satisfied; `Available` condition true |
| **Upgrade** | New ReplicaSet scaled up; old scaled down per strategy |

---

## How Deployments are used in the DocSync project

| Concern | Manifest |
|---------|----------|
| **Stable app name** | `metadata.name: docsync` |
| **Service wiring** | Pod labels **`app: docsync`** match **`docsync-service`** / **`docsync-nodeport`** **selectors** in `k8s/service.yaml` and `k8s/service-nodeport.yaml` |
| **HTTP port** | Container listens on **3000**; Service maps **80 → 3000** |
| **Health** | **Liveness** and **readiness** probes on `/health` |
| **Capacity guardrails** | **requests** and **limits** for CPU/memory |

Canonical manifest: [`k8s/deployment.yaml`](../k8s/deployment.yaml).

---

## Commands used

```bash
kubectl apply -f k8s/deployment.yaml
kubectl get deployments
kubectl get rs
kubectl get pods
kubectl describe deployment docsync
kubectl rollout status deployment/docsync
kubectl rollout history deployment/docsync
```

Read-only helper:

```bash
chmod +x scripts/k8s-deployment-check.sh
./scripts/k8s-deployment-check.sh
```

---

## Expected outputs

| Command | Pass criteria |
|---------|----------------|
| `kubectl apply -f k8s/deployment.yaml` | `deployment.apps/docsync configured` (or `created`) |
| `kubectl get deployments` | `READY` matches desired replicas (e.g. `2/2`) when Pods healthy |
| `kubectl get rs` | At least one ReplicaSet for `docsync`; current revision with desired Pods |
| `kubectl get pods` | Pods show `Running` and `READY` once image pulls and probes succeed |
| `kubectl describe deployment docsync` | **Events** show scaling and rollout progress |
| `kubectl rollout status deployment/docsync` | `successfully rolled out` when complete |

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `k8s/deployment.yaml` (editor or terminal) | `docs/proofs/4.21-deployment-yaml.png` |
| 2 | `kubectl get deployments` | `docs/proofs/4.21-get-deployments.png` |
| 3 | `kubectl get rs` | `docs/proofs/4.21-get-rs.png` |
| 4 | `kubectl rollout status deployment/docsync` | `docs/proofs/4.21-rollout-status.png` |
| 5 | `kubectl describe deployment docsync` | `docs/proofs/4.21-describe-deployment.png` |
| 6 | `./scripts/k8s-deployment-check.sh` | `docs/proofs/4.21-script-deployment-check.png` |

---

## Validation checklist

- [ ] Explained **Deployment vs Pod** and **Deployment → ReplicaSet → Pod** chain  
- [ ] Applied **`k8s/deployment.yaml`** in a cluster (or dry-run per instructor policy)  
- [ ] Verified **labels** remain compatible with **Services** (`app: docsync` matches `k8s/service.yaml` and `k8s/service-nodeport.yaml`)  
- [ ] Inspected **rollout status** and **history**  
- [ ] Ran **`scripts/k8s-deployment-check.sh`** (read-only)  
- [ ] Captured proofs per **`docs/proofs/README.md`** (Assignment **4.21**)  
- [ ] Opened PR **`spr16-k8s-deployments`** for review  

---

## Learning outcome

After **Assignment 4.21 / A-16**, you can:

- Operate **Deployments** as the primary workload API for stateless apps  
- Interpret **rollout** status and revision history  
- Align **DocSync** manifests with **Service** selectors and **probe**-driven availability  

---

## References

- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)  
- [Rolling update](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment)  
