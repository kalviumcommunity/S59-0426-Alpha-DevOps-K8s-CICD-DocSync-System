# Assignment A-18 / 4.25 — Implementing Health Checks: Liveness and Readiness Probes

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Gouri  
**Branch / PR identifier:** `spr18-health-checks-probes`  

**Prerequisite context:** [A-16 / 4.21 — Deployments](A-16-k8s-deployments.md) and [A-17 / 4.22 — Services](A-17-k8s-services.md) establish how DocSync Pods are scheduled and exposed; **probes** decide when those Pods are **live**, **ready**, and eligible for **traffic**.

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.25** (tracker ID: **A-18**) |
| **Module reference** | **Module 7** (or equivalent) — Container **liveness** and **readiness** probes, HTTP health checks, and rollout safety |
| **Objective** | Explain **liveness vs readiness**; relate probes to **DocSync `/health`**; verify **`k8s/deployment.yaml`** probe fields; practice inspection commands; capture proofs; use **`scripts/k8s-health-check.sh`** for read-only diagnostics. |

---

## What are health checks

**Health checks** (in Kubernetes, **probes**) are periodic tests the **kubelet** runs against each container. They inform decisions about **restarts** (liveness) and **traffic membership** (readiness).

---

## Difference between liveness and readiness probes

| Dimension | **Liveness** | **Readiness** |
|-----------|--------------|----------------|
| **Question asked** | “Should this container be **restarted**?” | “Should this Pod receive **traffic**?” |
| **On sustained failure** | **Container restart** (same Pod) | Pod marked **NotReady** → dropped from **Service Endpoints** |
| **Typical signal** | Deadlock / hung process (still passes TCP accept) | DB warming, cache fill, dependency outage |

Both may use the **same HTTP path** (`/health`) when the app exposes a single lightweight status—as DocSync does—while semantics still differ.

---

## Why probes are important in Kubernetes

| Reason | Benefit |
|--------|---------|
| **Automation** | Controllers act on signal without human paging for every blip |
| **Traffic safety** | Readiness prevents routing to half-started Pods |
| **Recovery** | Liveness clears wedged processes without draining the whole node |

---

## How probes prevent bad deployments

During a **RollingUpdate**, new Pods must become **Ready** (readiness) before old Pods scale down (with `maxUnavailable: 0` in DocSync). If the new revision fails probes, the Deployment **stalls** or **backs off**, limiting blast radius.

---

## How probes support self-healing

- **Liveness** failures beyond `failureThreshold` trigger **container restart**, recreating the process inside the same Pod sandbox.  
- **Readiness** flapping removes/adds the Pod from **Endpoints** automatically as health returns.

---

## Health endpoint used in DocSync

| Item | Detail |
|------|--------|
| **Path** | **`GET /health`** |
| **Port** | **3000** (container `PORT` / Express listener) |
| **Manifest** | `livenessProbe` and `readinessProbe` **`httpGet`** blocks in [`k8s/deployment.yaml`](../k8s/deployment.yaml) |

---

## Failure scenarios detected by probes

| Scenario | Typical probe impact |
|----------|----------------------|
| Process hung (no response) | **Liveness** timeout → restart after threshold |
| Still starting (DB, TLS warmup) | **Readiness** fails → no traffic until `initialDelaySeconds` + success |
| Wrong image / crash loop | Both may fail; **describe pod** shows `CrashLoopBackOff` + probe events |
| Wrong `path` / port | Perpetual **Unhealthy** events |

---

## How probes improve reliability and production readiness

| Practice | Outcome |
|----------|---------|
| Tune **`initialDelaySeconds`** | Fewer false-positive restarts on cold start |
| Tune **`periodSeconds` / `timeoutSeconds`** | Balance API load vs detection speed |
| Align with **Service** rollout | Only **Ready** Pods serve `docsync-service` traffic |

---

## Commands used

```bash
kubectl apply -f k8s/deployment.yaml
kubectl describe deployment docsync
kubectl get pods
kubectl describe pod <pod-name>
kubectl rollout status deployment/docsync
kubectl logs <pod-name>
```

Read-only helper:

```bash
chmod +x scripts/k8s-health-check.sh
./scripts/k8s-health-check.sh
```

---

## Expected outputs

| Command | Pass criteria |
|---------|----------------|
| `kubectl apply -f k8s/deployment.yaml` | Deployment accepted; Pods recreate if spec changed |
| `kubectl describe deployment docsync` | Shows **Liveness** and **Readiness** HTTP `/health` on **3000** |
| `kubectl get pods` | `READY` column `1/1` when readiness succeeds |
| `kubectl describe pod …` | **Events** mention probe success/failure (`Unhealthy`, `Killing`, …) |
| `kubectl rollout status …` | `successfully rolled out` when complete |
| `kubectl logs …` | Application logs without silent crash right after start |

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `k8s/deployment.yaml` probe section | `docs/proofs/4.25-deployment-probes.png` |
| 2 | `kubectl describe deployment docsync` | `docs/proofs/4.25-describe-deployment.png` |
| 3 | `kubectl describe pod …` (probe events) | `docs/proofs/4.25-describe-pod-probes.png` |
| 4 | `kubectl rollout status deployment/docsync` | `docs/proofs/4.25-rollout-status.png` |
| 5 | `curl` `/health` via port-forward | `docs/proofs/4.25-health-port-forward.png` |
| 6 | `./scripts/k8s-health-check.sh` | `docs/proofs/4.25-script-health-check.png` |

---

## Validation checklist

- [ ] Documented **liveness vs readiness** semantics  
- [ ] Verified **`k8s/deployment.yaml`** uses **HTTP GET `/health`** on port **3000** with timing fields  
- [ ] Observed **probe events** on a running Pod  
- [ ] Confirmed **rollout** completes with probes enabled  
- [ ] Tested **`/health`** through **`kubectl port-forward`**  
- [ ] Ran **`scripts/k8s-health-check.sh`** (read-only)  
- [ ] Captured proofs per **`docs/proofs/README.md`** (Assignment **4.25**)  
- [ ] Opened PR **`spr18-health-checks-probes`** for review  

---

## Learning outcome

After **Assignment 4.25 / A-18**, you can:

- Configure **HTTP probes** appropriate for a Node.js HTTP service  
- Tune **delays and thresholds** to reduce flapping  
- Debug **Unhealthy** probe events alongside **Deployment** rollouts  

---

## References

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)  
