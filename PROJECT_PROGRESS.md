# Project Progress — Sprint #3

**Course / initiative:** DevOps with Kubernetes & CI/CD  
**Project codename:** DocSync — Real-Time Document Editing Service  
**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Document version:** 1.9  
**Last updated:** May 12, 2026  
**Active team size:** 2 (Samarth, Gouri)  

---

## 1. Project Overview

### 1.1 Brief explanation

DocSync is a containerized Node.js service that demonstrates an **immutable artifact** delivery model: every change is validated in CI, packaged as a Docker image, published to a container registry, and intended for deployment on Kubernetes. The repository documents the full **Source → Image → Registry → Cluster** path aligned with industry practice.

### 1.2 Objective of the sprint

| Objective | Description |
|-----------|-------------|
| **Standardize environments** | Eliminate drift between developer laptops and deployment targets using Docker. |
| **Automate quality gates** | Enforce linting and tests on every PR and protected branch via GitHub Actions. |
| **Prepare for orchestration** | Express the application as Kubernetes workloads (Deployments, Services) with health checks and resource limits. |
| **Traceability** | Tie image tags and digests to Git commits for auditability and rollback. |

### 1.3 DevOps goals

- [x] Version-controlled infrastructure and pipeline definitions (`k8s/`, `.github/workflows/`)
- [x] Multi-stage Docker build with non-root user and health check
- [x] CI pipeline: checkout → environment verification → lint → test → build → push (on `main`)
- [x] CD scaffolding: documented deploy/verify stages (production `kubectl` wiring to be completed per cluster access)
- [ ] Helm packaging and GitOps-style promotion (planned)
- [ ] Full cluster integration testing and observability stack (Prometheus / Grafana — planned)

---

## 2. Tech Stack

| Category | Technology / tool | Role in project |
|----------|-------------------|-----------------|
| **VCS** | Git & GitHub | Source control, PR reviews, workflow triggers |
| **Runtime** | Node.js 20 (Alpine in container) | Application runtime |
| **Containers** | Docker | Build, run, and ship immutable images |
| **Orchestration** | Kubernetes | Desired-state deployment of DocSync |
| **Package manager (K8s)** | Helm | *Planned* — templated releases and values per environment |
| **CI/CD** | GitHub Actions | Automated lint, test, build, registry push |
| **CLI** | `kubectl` | Cluster inspection, apply, rollout, rollback |
| **Host OS** | Linux (local / CI `ubuntu-latest`) | Dev and pipeline execution environment |
| **Registries** | GitHub Container Registry (GHCR); Docker Hub optional | Image storage and pull targets for K8s |
| **Observability** | Prometheus / Grafana | *Planned* — metrics, dashboards, alerting |

Supporting: ESLint, `npm ci`, `wget` (image health check), GitHub Actions `docker/*` actions.

---

## 3. Work Completed Till Now

### 3.1 Environment setup

- [x] Node.js **20** aligned with Dockerfile and `setup-node` in CI  
- [x] Local verification script concept (`scripts/pre-build-check.sh`; CI runs inline pre-build checks)  
- [x] Documentation for DevOps setup (`docs/DEVOPS-SETUP.md`)  

### 3.2 Git repository setup

- [x] Monorepo layout for application, Kubernetes manifests, docs, and workflows  
- [x] `.gitignore` for dependencies and local artifacts  
- [x] Branch triggers: `push` and `pull_request` to `main` for CI  

### 3.3 Docker setup

- [x] Multi-stage `Dockerfile`: dependency install in builder, minimal production stage  
- [x] Non-root user (`appuser` / `appgroup`), `NODE_ENV=production`, exposed port **3000**  
- [x] `HEALTHCHECK` against `/health`  
- [x] `.dockerignore` to keep build context lean  

### 3.4 Kubernetes setup

- [x] `Deployment` (`k8s/deployment.yaml`): 3 replicas, rolling update strategy, probes, resource requests/limits  
- [x] `Service` (`k8s/service.yaml`): `ClusterIP`, port 80 → target 3000  
- [ ] Ingress, TLS, and external DNS — *pending / environment-specific*  
- [ ] Helm chart — *planned*  

### 3.5 CI/CD setup

- [x] Workflow `DocSync CI/CD Pipeline` (`.github/workflows/ci-cd.yml`)  
- [x] Jobs: **CI** (lint → test), **build-and-push** (after CI, on `main` push), **deploy-and-verify** (documented CD steps)  
- [x] GHCR login via `GITHUB_TOKEN`, image metadata via `docker/metadata-action`  

### 3.6 Application setup

- [x] Express-style service under `src/` with document logic module  
- [x] Unit tests under `tests/` (`npm test`)  
- [x] Lint gate (`npm run lint`)  

### 3.7 Deployments and testing

- [x] Automated **unit** and **lint** execution in CI on every qualifying event  
- [x] Docker image **build and push** to GHCR on successful `main` push  
- [x] CD job currently **simulates** cluster steps (echo-based); real `kubectl apply` pending cluster credentials  
- [x] Supplementary verification notes in `docs/verification-output.txt` (as available in repo)  

---

## 4. Docker Progress

| Milestone | Status | Notes |
|-----------|--------|--------|
| Docker installation (local / CI) | Done | CI runner provides Docker; team verifies local installs |
| Dockerfile creation | Done | Multi-stage, Node 20 Alpine, production deps |
| Docker image build | Done | Via `docker build` locally and `docker/build-push-action` in CI |
| Container execution | Done | `docker run` with published port 3000 (team validation) |
| Docker Compose setup | Optional / TBD | Add `compose.yaml` if multi-service local stack is required |
| Debugging and logs | Ongoing | `docker logs`, `docker inspect`, application logging |
| Image tagging | Done | SHA, semver pattern, `latest` via metadata action |
| Docker Hub / GHCR push | Done (GHCR) | Push on `main` after CI success; Docker Hub optional mirror |

**Highlights**

- **Security:** non-root container user  
- **Operability:** built-in health check compatible with orchestrator probes  
- **Supply chain:** immutable digest emitted by build job for traceability  

---

## 5. Kubernetes Progress

| Area | Status | Details |
|------|--------|---------|
| Local cluster setup | Partial | e.g. minikube, kind, or k3d — per team environment |
| Pods | Defined | Via `Deployment` pod template |
| Deployments | Done | `docsync`, rolling updates, `maxUnavailable: 0` |
| Services | Done | `ClusterIP` fronting port 80 → 3000 |
| ConfigMaps | Planned | Externalize config beyond env block in manifest |
| Secrets | Planned | Registry pull secrets if private; app secrets via Sealed Secrets or external store |
| Scaling | Supported | `replicas` field (currently 3); HPA planned |
| Rollbacks | Documented | `kubectl rollout undo` / revision pinning — see README pipeline narrative |
| Ingress | Planned | NGINX / cloud LB integration TBD |
| Helm usage | Planned | Chart for templated image tag and env values |

---

## 6. CI/CD Progress

### 6.1 GitHub Actions workflows

| Workflow file | Purpose |
|---------------|---------|
| `.github/workflows/ci-cd.yml` | End-to-end DocSync pipeline (CI + artifact + CD scaffold) |

**Triggers:** `push` and `pull_request` to `main`.

### 6.2 Build automation

- [x] Pre-build: Node, npm, Docker, Git version checks; `Dockerfile` / `package.json` presence  
- [x] `npm ci` for reproducible installs  

### 6.3 Test automation

- [x] `npm test` in CI  
- [x] `npm run lint` as quality gate  

### 6.4 Docker image automation

- [x] `docker/login-action` → GHCR  
- [x] `docker/metadata-action` for tags and labels  
- [x] `docker/build-push-action` with `push: true` on `main`  

### 6.5 Kubernetes deployment automation

- [x] Documented steps in CD job (checkout, would update manifest image, `kubectl apply`, rollout status)  
- [ ] Live `kubectl` from Actions (requires kubeconfig / cloud integration secrets)  

### 6.6 Secrets management

| Secret / credential | Usage |
|---------------------|--------|
| `GITHUB_TOKEN` (packages write) | GHCR push from Actions |
| *Planned* | Kubeconfig, cloud registry tokens, app secrets via GitHub Environments |

---

## 7. Repository Structure

```text
S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System/
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── docs/
│   ├── DEVOPS-SETUP.md
│   ├── PIPELINE.md
│   ├── PIPELINE_DESIGN.md
│   └── verification-output.txt
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
├── scripts/
│   └── pre-build-check.sh
├── src/
│   ├── document.js
│   └── server.js
├── tests/
│   └── document.test.js
├── .dockerignore
├── .eslintrc.json
├── .gitignore
├── Dockerfile
├── package.json
├── package-lock.json
├── PROJECT_PROGRESS.md          ← this document
└── README.md
```

---

## 8. Assignment & PR Tracker

> **Active roster:** Samarth and Gouri (10 assignments each). Update **PR Name** and **Status** as milestones close. **Stream** indicates the primary competency area; both members review cross-cutting PRs (image ↔ manifest ↔ pipeline).

| Assignment # | Stream | Task Name | PR Name | Status | Assigned |
|--------------|--------|-----------|---------|--------|----------|
| A-01 | Docker / Containerization | 4.8 — Setting Up DevOps Workstation: Git, Docker, kubectl, Helm, and CLI Tools | `spr1-devops-workstation` | In Review | Samarth |
| A-02 | Kubernetes / CI-CD | 4.9 — Understanding DevOps Principles, CI/CD Concepts, and Delivery Pipelines | `spr2-devops-principles` | In Review | Samarth |
| A-03 | Docker / Containerization | 4.10 — Exploring Git Repositories, Branching Models, and Commit Conventions | `spr3-git-workflow` | In Review | Samarth |
| A-04 | Docker / Containerization | 4.11 — Linux Filesystem Structure & Permissions for DevOps Workflows | `spr4-linux-permissions` | In Review | Samarth |
| A-05 | Docker / Containerization | 4.12 — Introduction to Containers and Containerization Concepts | `spr5-containerization-concepts` | In Review | Samarth |
| A-06 | Docker / Containerization | 4.13 — Understanding Docker Architecture: Images, Containers, and Layers | `spr6-docker-architecture` | In Review | Samarth |
| A-07 | Docker / Containerization | 4.14 — Writing Dockerfiles: Base Images, Layers, Caching, and Best Practices | `spr7-dockerfile-basics` | In Review | Samarth |
| A-08 | Docker / Containerization | 4.14 — Dockerfile Optimization: Layers, Caching, Security, and Best Practices | `spr8-dockerfile-optimization` | In Review | Samarth |
| A-09 | Docker / Containerization | Local `docker run` & health validation | `pr/A-09-docker-run-health` | TBD | Samarth |
| A-10 | Kubernetes / CI-CD | Kubernetes Deployment manifest | `pr/A-10-k8s-deployment` | TBD | Gouri |
| A-11 | Kubernetes / CI-CD | Kubernetes Service manifest | `pr/A-11-k8s-service` | TBD | Gouri |
| A-12 | Kubernetes / CI-CD | Probes & resource limits tuning | `pr/A-12-probes-resources` | TBD | Gouri |
| A-13 | Kubernetes / CI-CD | Local cluster bring-up (kind/minikube) | `pr/A-13-local-cluster` | TBD | Gouri |
| A-14 | Kubernetes / CI-CD | GitHub Actions CI (lint + test) | `pr/A-14-gha-ci` | TBD | Gouri |
| A-15 | Docker / Containerization | GitHub Actions build & GHCR push | `pr/A-15-gha-build-push` | TBD | Samarth |
| A-16 | Kubernetes / CI-CD | CD scaffold / deploy job | `pr/A-16-cd-scaffold` | TBD | Gouri |
| A-17 | Kubernetes / CI-CD | Pipeline documentation | `pr/A-17-pipeline-docs` | TBD | Gouri |
| A-18 | Kubernetes / CI-CD | Rollback runbook & verification | `pr/A-18-rollback-runbook` | TBD | Gouri |
| A-19 | Kubernetes / CI-CD | Secrets & environments design | `pr/A-19-secrets-design` | TBD | Gouri |
| A-20 | Kubernetes / CI-CD | Sprint retrospective & demo assets | `pr/A-20-sprint-retro-demo` | TBD | Gouri |

**Status legend (for team use):** `Not Started` · `In Progress` · `In Review` · `Done` · `Blocked`

---

## 9. Commands Used

### 9.1 Linux & shell

```bash
node --version && npm --version
chmod +x scripts/pre-build-check.sh && ./scripts/pre-build-check.sh
```

### 9.2 Git & GitHub

```bash
git clone <repository-url>
git checkout -b feature/your-branch
git add . && git commit -m "Describe change"
git push -u origin feature/your-branch
```

### 9.3 Docker

```bash
docker build -t docsync:local .
docker run --rm -p 3000:3000 docsync:local
docker images
docker ps
docker logs <container_id>
docker tag docsync:local ghcr.io/<org>/<repo>:<tag>
docker push ghcr.io/<org>/<repo>:<tag>
```

### 9.4 Kubernetes

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl get pods,svc,deploy -l app=docsync
kubectl describe deployment docsync
kubectl logs -l app=docsync --tail=100 -f
kubectl rollout status deployment/docsync
kubectl rollout undo deployment/docsync
```

---

## 10. Screenshots / Proof Section

> Insert images or links below for academic submission and stakeholder review. Recommended naming: `proof-<date>-<topic>.png`.

| # | Topic | Artifact | Location / link |
|---|--------|----------|-----------------|
| 1 | GitHub Actions — CI green | *Placeholder* | e.g. Actions run URL |
| 2 | GitHub Actions — image pushed to GHCR | *Placeholder* | Registry package page |
| 3 | `docker ps` / local container | *Placeholder* | Attach screenshot |
| 4 | `curl` / browser — `/health` OK | *Placeholder* | Attach screenshot |
| 5 | `kubectl get pods` | *Placeholder* | Attach screenshot |
| 6 | `kubectl get svc` | *Placeholder* | Attach screenshot |
| 7 | Rollout success | *Placeholder* | Attach screenshot |
| 8 | PR review / approval | *Placeholder* | Attach screenshot |

---

## 11. Team Responsibilities

> **Team size:** two active members. Ownership follows a **platform split**: one lead for **container artifact quality** (image, local run, registry handoff), one for **delivery automation and cluster** (workloads, pipeline stages, operational runbooks). Both participate in PR review on the boundary (image tags in manifests, probe paths vs. container health).

| Team member | Primary responsibilities | Supporting areas |
|-------------|-------------------------|------------------|
| **Samarth** | **Docker / containerization lead:** `Dockerfile` lifecycle (initial → hardened multi-stage), `.dockerignore`, local image build/run and `/health` validation, application readiness (lint/test config at repo level), repository bootstrap docs, branch/review hygiene, **GitHub Actions job that builds and pushes** the image to GHCR (pairs with Gouri on workflow file structure). | Image digest/tag communication to K8s manifests; troubleshooting failed image layers in CI. |
| **Gouri** | **Kubernetes / CI-CD lead:** `Deployment` / `Service` manifests, probes and resource tuning, local cluster bring-up, **GitHub Actions CI** (lint + test gates), CD scaffold and future live `kubectl` integration, pipeline and rollback documentation, secrets/environments design, sprint demo and stakeholder-facing artifacts. | Coordinating with Samarth on registry image name/tag used in `k8s/deployment.yaml`; validating rollouts after image changes. |

---

## 12. Current Status

### 12.1 Completion summary

| Workstream | Completed | Ongoing | Pending |
|------------|-----------|---------|---------|
| Environment & Git | Core setup | Fine-tuning branch rules | Org-wide policies |
| Docker | Multi-stage image, health check, CI build/push | Compose (if needed) | Optional Hub mirror |
| Kubernetes | Deployment + Service + probes | Local cluster validation | Ingress, Helm, HPA |
| CI/CD | Lint, test, build, GHCR push | Live deploy from Actions | Full CD with cluster auth |
| Observability | — | Design | Prometheus / Grafana |

### 12.2 Overall sprint health

- **Documentation:** Strong (`README.md`, `docs/PIPELINE*.md`, this progress file).  
- **Automation:** CI and registry path implemented; CD is intentionally scaffolded until cluster access is standardized.  
- **Risk:** Production deploy automation blocked on secure kubeconfig handling — track under A-16 / secrets work.  
- **Team capacity:** Two active members; the Docker/Kubernetes split in §8 and §11 keeps ownership clear while both review boundary changes (e.g., image reference in manifests, workflow edits).

---

## 13. Next Milestones

| Priority | Milestone | Target outcome |
|----------|-----------|----------------|
| P0 | Wire **live `kubectl`** from GitHub Actions (or approved GitOps tool) | Repeatable deploys from pipeline |
| P0 | Parameterize **image** in `k8s/deployment.yaml` (Kustomize or Helm) | No manual YAML edits per release |
| P1 | Introduce **Helm** chart + values for `dev` / `staging` / `prod` | Environment-specific config |
| P1 | **Ingress** + TLS (cert-manager or cloud-native) | External HTTPS access |
| P2 | **HPA** and/or cluster autoscaling | Elastic capacity |
| P2 | **Prometheus** metrics export + **Grafana** dashboards | SLO-driven operations |
| P3 | **Docker Compose** for ancillary services (if any) | Faster full-stack local dev |

---

## Document control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-05-12 | Project team | Initial PROJECT_PROGRESS.md aligned with repository state |
| 1.1 | 2026-05-12 | Samarth, Gouri | Two-member roster; assignment tracker and responsibility matrix updated |
| 1.2 | 2026-05-12 | Samarth | Sprint #3 PR1: A-01 / 4.8 workstation docs, proofs checklist, tracker (`spr1-devops-workstation`) |
| 1.3 | 2026-05-12 | Samarth | Sprint #3 PR2: A-02 / 4.9 DevOps principles doc, proofs checklist, tracker (`spr2-devops-principles`) |
| 1.4 | 2026-05-12 | Samarth | Sprint #3 PR3: A-03 / 4.10 git workflow doc, proofs checklist, tracker (`spr3-git-workflow`) |
| 1.5 | 2026-05-12 | Samarth | Sprint #3 PR4: A-04 / 4.11 Linux permissions doc, proofs checklist, tracker (`spr4-linux-permissions`) |
| 1.6 | 2026-05-12 | Samarth | Sprint #3 PR5: A-05 / 4.12 containerization concepts doc, proofs checklist, tracker (`spr5-containerization-concepts`) |
| 1.7 | 2026-05-12 | Samarth | Sprint #3 PR6: A-06 / 4.13 Docker architecture doc, proofs checklist, tracker (`spr6-docker-architecture`) |
| 1.8 | 2026-05-12 | Samarth | Sprint #3 PR7: A-07 / 4.14 Dockerfile basics, Dockerfile update, proofs, tracker (`spr7-dockerfile-basics`) |
| 1.9 | 2026-05-12 | Samarth | Sprint #3 PR8: A-08 / 4.14 Dockerfile optimization, .dockerignore, proofs, tracker (`spr8-dockerfile-optimization`) |

---

*This file is maintained by the DocSync DevOps sprint team (Samarth, Gouri). Update sections 8, 10, and 11 as assignments close and evidence is collected.*
