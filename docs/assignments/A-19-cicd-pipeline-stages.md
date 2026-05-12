# Assignment A-19 / 4.36 — Understanding CI/CD Pipeline Design and Workflow Stages

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Gouri  
**Branch / PR identifier:** `spr19-cicd-pipeline-stages`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.36** (tracker ID: **A-19**) |
| **Module reference** | **Module 8–9** (or equivalent) — CI/CD **pipeline stages**, responsibility boundaries, and production readiness |
| **Objective** | Define **CI vs CD vs deployment**; enumerate **DocSync** pipeline stages aligned with **GitHub Actions**; document **inputs/outputs**, **failure handling**, and **rollback** thinking; cross-link the stage reference [`docs/pipeline/PIPELINE_STAGES.md`](../pipeline/PIPELINE_STAGES.md). |

---

## What is a CI/CD pipeline

A **CI/CD pipeline** is an **automated sequence** of steps triggered by source-control events (for example, **push** or **pull_request**). It enforces **quality gates**, produces **immutable artifacts** (container images), and (when enabled) drives **delivery** toward runtime environments.

---

## Difference between CI, CD, and deployment

| Term | Meaning | In DocSync |
|------|---------|------------|
| **CI (Continuous Integration)** | Frequent **integration** of changes with **automated validation** | Job **`ci`**: checkout → install → **lint** → **test** |
| **CD (Continuous Delivery/Deployment)** | **Automated promotion** of validated artifacts toward an environment | Jobs **`build-and-push`** and **`deploy-and-verify`** on **`main`** |
| **Deployment** | The **act** of applying desired state to a cluster (e.g. `kubectl apply`) | **Documented** in workflow; live `kubectl` requires cluster credentials |

---

## Typical pipeline stages

| Phase | Stages (conceptual) |
|-------|---------------------|
| **Source** | Checkout pinned commit |
| **Build & validate** | Dependencies, lint, unit tests |
| **Package** | Docker image build |
| **Publish** | Registry push + provenance metadata |
| **Operate** | Deploy, verify, (rollback if needed) |

See the **authoritative stage table**: [`docs/pipeline/PIPELINE_STAGES.md`](../pipeline/PIPELINE_STAGES.md).

---

## Stage-by-stage overview (DocSync)

The sections below mirror the **logical** stages taught in coursework. The GitHub Actions workflow **`.github/workflows/ci-cd.yml`** implements these as **jobs** and **steps** (names may combine adjacent stages).

### Source stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | Pin the repository to the **exact commit** that triggered the workflow |
| **Tooling** | `actions/checkout@v4` |
| **Outputs** | Workspace with source at `${{ github.sha }}` |

### Install dependencies stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | **Reproducible** Node install (`npm ci` uses lockfile) |
| **Tooling** | `actions/setup-node@v4`, `npm ci` |
| **Outputs** | `node_modules` for lint/test |

### Lint stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | Static quality gate before execution |
| **Tooling** | `npm run lint` (ESLint) |
| **Failure** | **Blocks merge quality signal** on PRs; prevents packaging bad code |

### Test stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | Automated **unit** verification of application logic |
| **Tooling** | `npm test` |
| **Failure** | CI red; no image build on `main` |

### Build stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | Compile **immutable** OCI image from Dockerfile context |
| **Tooling** | `docker/build-push-action` (with `push: true` on `main` after CI passes) |

### Docker image creation stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | Package runtime + app bits as a **versioned artifact** |
| **Outputs** | Image digest + tags (see `docker/metadata-action`) |

### Registry push stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | Store image in **GHCR** for Kubernetes to pull |
| **Tooling** | `docker/login-action`, `GITHUB_TOKEN` (`packages: write`) |

### Deployment stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | Apply **Deployment/Service** manifests with the **new image reference** |
| **Today** | **Documented echo** in workflow — production wiring uses secured kubeconfig |

### Verification stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | **Smoke** readiness: rollout status, `/health`, log sanity |
| **Today** | **Documented echo** — real checks run against live cluster |

### Rollback stage

| Aspect | Detail |
|--------|--------|
| **Purpose** | Restore **last known good** revision when verification fails |
| **Typical tooling** | `kubectl rollout undo`, GitOps revert, or redeploy previous digest |

---

## How this project’s pipeline should work

```text
Git push / PR
    → Source (checkout)
    → Install (npm ci)
    → Lint
    → Test
    → [main only] Build image
    → [main only] Push to GHCR
    → [main only] Deploy (kubectl apply — when credentialed)
    → Verify (/health, rollout status)
    → (Rollback if verification fails)
```

---

## Source → Build → Test → Image → Registry → Kubernetes → Verify flow

| Step | Owner / system | Artifact or signal |
|------|----------------|---------------------|
| **Source** | Developer + Git | Commit SHA |
| **Test** | CI runner | Pass/fail |
| **Image** | Docker + Dockerfile | OCI layers |
| **Registry** | GHCR | Pullable tag + digest |
| **Kubernetes** | Cluster controllers | Running Pods |
| **Verify** | Operator / automation | Healthy endpoints |

---

## Responsibility boundaries

| Role | Responsibility |
|------|----------------|
| **Developer** | Correct code, meaningful tests, sensible resource requests |
| **Docker** | Reproducible image, non-root user, health endpoint |
| **CI/CD (GitHub Actions)** | Orchestrate stages, secrets injection policy, promotion gates |
| **Kubernetes** | Schedule Pods, enforce probes, roll out **desired state** |

---

## Commands / examples (local parity)

```bash
npm ci
npm run lint
npm test
docker build -t docsync:local .
```

**Registry (illustrative):**

```bash
docker tag docsync:local ghcr.io/<org>/<repo>:<tag>
docker push ghcr.io/<org>/<repo>:<tag>
```

**Cluster (when configured):**

```bash
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/docsync
```

---

## Expected outputs

| Stage | “Green” signal |
|-------|----------------|
| Lint | ESLint exits **0** |
| Test | Jest (or runner) exits **0** |
| Build/Push | Image digest printed; package visible in GHCR |
| Verify | `rollout status` success; **HTTP 200** on `/health` |

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `docs/pipeline/PIPELINE_STAGES.md` or `docs/PIPELINE_DESIGN.md` | `docs/proofs/4.36-pipeline-docs.png` |
| 2 | GitHub Actions run (`DocSync CI/CD Pipeline`) | `docs/proofs/4.36-gha-workflow.png` |
| 3 | PR **Checks** tab (lint + test green) | `docs/proofs/4.36-pr-checks.png` |
| 4 | Stage explanation (assignment or PIPELINE_STAGES excerpt) | `docs/proofs/4.36-stage-explanation.png` |
| 5 | Validation checklist (this doc or proofs README) | `docs/proofs/4.36-validation-checklist.png` |

---

## Validation checklist

- [ ] Can articulate **CI vs CD vs deployment**  
- [ ] Mapped each **logical stage** to DocSync’s **workflow jobs**  
- [ ] Read [`docs/pipeline/PIPELINE_STAGES.md`](../pipeline/PIPELINE_STAGES.md) end-to-end  
- [ ] Captured proofs for **Assignment 4.36** in `docs/proofs/README.md`  
- [ ] Opened PR **`spr19-cicd-pipeline-stages`** for review  

---

## Learning outcome

After **Assignment 4.36 / A-19**, you can:

- Design and defend a **multi-stage** pipeline appropriate for a small service  
- Place **rollback** and **verification** as first-class operational concerns  
- Explain **who owns what** from commit to running Pod  

---

## References (repository)

| Document | Role |
|----------|------|
| [`docs/pipeline/PIPELINE_STAGES.md`](../pipeline/PIPELINE_STAGES.md) | **Stage table** (inputs, outputs, failures, production notes) |
| [`docs/PIPELINE_DESIGN.md`](../PIPELINE_DESIGN.md) | Narrative **7-stage** design rationale |
| [`.github/workflows/ci-cd.yml`](../../.github/workflows/ci-cd.yml) | Executable workflow (**do not edit** in this assignment) |
