# Assignment A-17 / 4.22 — Configuring Kubernetes Services (ClusterIP, NodePort)

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Gouri  
**Branch / PR identifier:** `spr17-k8s-services`  

**Prerequisite context:** [A-16 / 4.21 — Deployments](A-16-k8s-deployments.md) manages DocSync **Pods**; **Services** provide stable networking to those Pods.

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.22** (tracker ID: **A-17**) |
| **Module reference** | **Module 6–7** (or equivalent) — Kubernetes **Service** API: **ClusterIP**, **NodePort**, selectors, **Endpoints** |
| **Objective** | Explain **Services** vs raw Pod IPs; compare **ClusterIP** and **NodePort**; wire **selectors** to the DocSync **Deployment**; practice **kubectl** inspection and **port-forward** health checks; capture proofs; use **`scripts/k8s-service-check.sh`** for read-only diagnostics. |

---

## What is a Kubernetes Service

A **Service** is a stable **virtual IP** (ClusterIP) and **DNS name** plus **port mapping** that load-balances traffic to **healthy Pod endpoints** matching a **label selector**. Clients talk to the Service; Kubernetes forwards to backing Pods.

---

## Why Services are needed

| Without a Service | With a Service |
|-------------------|----------------|
| Pod IPs change on reschedule | **Stable ClusterIP** and **DNS** |
| No built-in load spread across replicas | **kube-proxy** distributes traffic |
| Hard to reference from other apps | Standard in-cluster discovery |

---

## ClusterIP explanation

| Property | Detail |
|----------|--------|
| **Reachability** | **Inside the cluster only** (Pods, other Services) |
| **Default type** | `spec.type: ClusterIP` |
| **DocSync manifest** | [`k8s/service.yaml`](../k8s/service.yaml) — resource name **`docsync-service`**, port **80 → 3000** |

---

## NodePort explanation

| Property | Detail |
|----------|--------|
| **Reachability** | Same ClusterIP behavior **plus** a **high port** on **each Node’s IP** |
| **Use case** | Quick demos / lab access without Ingress (not a production external LB) |
| **DocSync manifest** | [`k8s/service-nodeport.yaml`](../k8s/service-nodeport.yaml) — **`docsync-nodeport`**; **`nodePort` omitted** so the control plane picks a free port |

---

## Service discovery basics

| Mechanism | Example |
|-----------|---------|
| **DNS (in-cluster)** | `docsync-service.default.svc.cluster.local` |
| **Environment variables** | Legacy `SERVICE_HOST` / `SERVICE_PORT` (optional pattern) |
| **Headless Services** | `clusterIP: None` — out of scope for 4.22 |

---

## Selector and label matching

- **Service** `spec.selector` must match **Pod** `metadata.labels` on the **DocSync Deployment** template (`app: docsync`).  
- Only Pods with **all** selector key/value pairs receive traffic.

---

## Port vs targetPort

| Field | Role |
|-------|------|
| **`port`** | The port the **Service** listens on (e.g. **80** for HTTP convention) |
| **`targetPort`** | The **containerPort** on Pods (DocSync listens on **3000**) |

**Example:** `port: 80`, `targetPort: 3000` — callers use `:80`; kube-proxy forwards to container `:3000`.

---

## How Services expose the DocSync Deployment

| Layer | Artifact |
|-------|----------|
| **Workload** | `deployment.apps/docsync` creates Pods labeled **`app: docsync`** |
| **ClusterIP** | `docsync-service` → stable internal access on **80** |
| **NodePort** | `docsync-nodeport` → same Pods, also exposed on each node’s **NodePort** |

---

## Difference between internal and external access

| Path | Access |
|------|--------|
| **ClusterIP only** | Other Pods in cluster; devs often use **`kubectl port-forward`** from laptop |
| **NodePort** | LAN / node IP + assigned high port |
| **Ingress / LoadBalancer** | Production north–south HTTP(S) — *planned for later sprints* |

---

## Commands used

```bash
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/service-nodeport.yaml
kubectl get svc
kubectl describe svc docsync-service
kubectl port-forward svc/docsync-service 3000:80
curl http://localhost:3000/health
```

Read-only helper:

```bash
chmod +x scripts/k8s-service-check.sh
./scripts/k8s-service-check.sh
```

---

## Expected outputs

| Step | Pass criteria |
|------|----------------|
| `kubectl apply -f k8s/service.yaml` | `service/docsync-service created` (or `unchanged`) |
| `kubectl apply -f k8s/service-nodeport.yaml` | `service/docsync-nodeport created` |
| `kubectl get svc` | `TYPE` shows **ClusterIP** and **NodePort**; NodePort row includes **`PORT(S)`** like `80:3xxxx/TCP` |
| `kubectl describe svc docsync-service` | **Endpoints** list Pod IPs when Pods are Ready |
| `kubectl port-forward …` | Terminal shows `Forwarding from 127.0.0.1:3000 -> 3000` (or similar) |
| `curl …/health` | HTTP **200** with JSON/OK body (once image runs) |

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `k8s/service.yaml` | `docs/proofs/4.22-service-clusterip.png` |
| 2 | `k8s/service-nodeport.yaml` | `docs/proofs/4.22-service-nodeport.png` |
| 3 | `kubectl get svc` | `docs/proofs/4.22-get-svc.png` |
| 4 | `kubectl describe svc docsync-service` | `docs/proofs/4.22-describe-svc.png` |
| 5 | `kubectl port-forward` session | `docs/proofs/4.22-port-forward.png` |
| 6 | `curl` health via forwarded port | `docs/proofs/4.22-curl-health.png` |
| 7 | `./scripts/k8s-service-check.sh` | `docs/proofs/4.22-script-service-check.png` |

---

## Validation checklist

- [ ] Explained **ClusterIP vs NodePort** and **port vs targetPort**  
- [ ] Verified **selectors** match **`k8s/deployment.yaml`** Pod labels  
- [ ] Applied **both** Service manifests in a cluster (or captured instructor cluster output)  
- [ ] Validated **Endpoints** show Ready Pod IPs  
- [ ] Exercised **`port-forward`** + **`curl /health`**  
- [ ] Ran **`scripts/k8s-service-check.sh`** (read-only)  
- [ ] Captured proofs per **`docs/proofs/README.md`** (Assignment **4.22**)  
- [ ] Opened PR **`spr17-k8s-services`** for review  

---

## Learning outcome

After **Assignment 4.22 / A-17**, you can:

- Choose a **Service type** appropriate for lab vs production exposure  
- Debug **missing endpoints** (selector mismatch, Pods not Ready, wrong namespace)  
- Use **port-forward** safely for local verification without publishing a LoadBalancer  

---

## References

- [Service](https://kubernetes.io/docs/concepts/services-networking/service/)  
- [Connecting applications with Services](https://kubernetes.io/docs/tutorials/services/connect-applications-service/)  
