# Assignment A-02 / 4.9 — DevOps Principles, CI/CD, and Delivery Pipelines

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr2-devops-principles`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.9** (tracker ID: **A-02**) |
| **Module reference** | **Module 4** — DevOps culture, continuous practices, and end-to-end delivery pipelines for cloud-native software |
| **Objective** | Explain **DevOps** as a set of practices and cultural norms, distinguish **continuous integration (CI)** from **continuous delivery/deployment (CD)**, map **pipeline stages** from source to Kubernetes, and relate these concepts to the **DocSync** repository and toolchain. |

---

## Introduction to DevOps

**DevOps** combines **development** and **operations** concerns into a shared model for delivering software: small batches of change, fast feedback, automation, and measurable quality. It is not a single tool—it is **how teams work** (collaboration, ownership of production outcomes) supported by **how systems are built** (automation, observability, immutable artifacts).

| Theme | What it means in practice |
|-------|---------------------------|
| **Culture** | Blameless postmortems, shared on-call, clear ownership of services |
| **Automation** | Repeatable builds, tests, and deployments—not manual runbooks for every release |
| **Measurement** | Lead time, deployment frequency, change failure rate, MTTR (DORA metrics) |
| **Sharing** | Documentation, internal platforms, and transparent pipelines |

---

## DevOps lifecycle

A common mental model is an **infinite loop** connecting plan, build, release, operate, and learn:

```text
Plan → Code → Build → Test → Release → Deploy → Operate → Monitor → Learn → Plan …
```

| Phase | Typical activities |
|-------|---------------------|
| **Plan / Code** | Issues, design, PRs, reviews |
| **Build / Test** | Compile/package, unit & integration tests, static analysis |
| **Release** | Versioned artifacts (e.g., container images), changelog |
| **Deploy** | Progressive rollout to staging/production |
| **Operate / Monitor** | Logs, metrics, traces, alerts |
| **Learn** | Incidents, capacity planning, backlog refinement |

---

## CI concepts

**Continuous Integration (CI)** means developers **merge small changes frequently** into a shared mainline, and each integration triggers an **automated build and test** pipeline. If the pipeline fails, the change is fixed or reverted before it blocks others.

| CI property | Description |
|-------------|-------------|
| **Fast feedback** | Minutes, not hours, to know if a change is safe |
| **Single source of truth** | One branch (e.g., `main`) is integration-ready |
| **Deterministic checks** | Same commands in CI as locally where possible (`npm ci`, `npm test`) |
| **Visible status** | Green/red checks on every PR |

---

## CD concepts

**Continuous Delivery (CD)** extends CI: the software is **always releasable**—every passing build could go to production with a **business decision** (button, tag, or policy). **Continuous Deployment** is stricter: every passing build is **automatically deployed** to production without a manual gate (suited to mature teams with strong tests and feature flags).

| Term | Automation boundary |
|------|------------------------|
| **Continuous Delivery** | Deploy-ready artifact; human or policy approves production |
| **Continuous Deployment** | Automated promotion to production after gates pass |

---

## CI vs CD

| Dimension | CI | CD (Delivery / Deployment) |
|-----------|----|----------------------------|
| **Primary question** | “Does this change **integrate** cleanly and pass quality gates?” | “Can we **ship** this change safely—and **do** we ship it?” |
| **Typical outputs** | Test reports, lint results, build logs | Staged/prod releases, rollout status, smoke tests |
| **Failure impact** | Broken build blocks merge | Failed deploy triggers rollback or halt |
| **DocSync alignment** | GitHub Actions: lint + test on PR/push | Build/push image; CD scaffold toward Kubernetes |

---

## Delivery pipeline stages

A **delivery pipeline** is an ordered sequence of stages, each with entry criteria and exit gates. A minimal cloud-native pipeline often looks like:

| Stage | Purpose | Example checks |
|-------|---------|----------------|
| **Source** | Immutable reference to code | Commit SHA, signed commits (optional) |
| **Build** | Produce runnable artifact | `npm ci`, compile, bundle |
| **Test** | Validate behavior & quality | Unit tests, lint, coverage thresholds |
| **Package** | Seal runtime + dependencies | `docker build` → image digest |
| **Publish** | Store artifact in registry | Push to GHCR with tags |
| **Deploy** | Apply desired state to environment | `kubectl apply`, Helm upgrade |
| **Verify** | Confirm health in target env | Smoke tests, probes, synthetic checks |

---

## Benefits of DevOps

| Benefit | Explanation |
|---------|-------------|
| **Shorter lead time** | Smaller changes flow faster with less risk |
| **Fewer defects in production** | Automated tests catch regressions early |
| **Predictable releases** | Pipelines encode “how we ship” |
| **Better recovery** | Rollbacks and replicas reduce blast radius |
| **Auditability** | Every deploy ties to an image digest and commit |

---

## Real-world DevOps workflow

1. Engineer opens a **feature branch**, implements change, runs tests locally.  
2. **Pull request** triggers CI on the shared platform (e.g., GitHub Actions).  
3. Reviewers approve; merge to **`main`** triggers **artifact build** (container image).  
4. Image is **tagged** (commit SHA, semver) and **pushed** to a registry.  
5. **Deployment** updates Kubernetes (rolling update), monitors **probes** and metrics.  
6. On failure, **rollback** to previous revision or automatic undo policy.  
7. **Observability** feeds incidents and backlog for the next iteration.

---

## DevOps tools overview

| Layer | Representative tools (illustrative) |
|-------|-------------------------------------|
| **VCS / collaboration** | Git, GitHub, GitLab |
| **CI/CD** | GitHub Actions, Jenkins, GitLab CI |
| **Containers** | Docker, containerd |
| **Registry** | GHCR, ECR, Docker Hub |
| **Orchestration** | Kubernetes, Helm |
| **Observability** | Prometheus, Grafana, OpenTelemetry |

DocSync uses **GitHub**, **GitHub Actions**, **Docker**, **GHCR**, and **Kubernetes manifests** in-repo—matching the table above at a teaching-friendly depth.

---

## How this project applies DevOps principles

| Principle | DocSync implementation |
|-----------|-------------------------|
| **Automation** | Workflow runs lint, test, and Docker build/push on `main` (see `.github/workflows/ci-cd.yml`) |
| **Immutable artifacts** | The runnable unit is a **Docker image**, not a mutable server directory |
| **Declarative infrastructure** | Kubernetes `Deployment` and `Service` YAML express desired state |
| **Separation of CI vs CD concerns** | CI validates; CD job documents deploy/verify steps for cluster integration |
| **Traceability** | Image metadata ties tags to Git SHA for rollback and audits |

---

## Example workflow: Source → Build → Test → Image → Registry → Kubernetes

```text
┌──────────┐   ┌───────────┐   ┌────────┐   ┌─────────────┐   ┌──────────┐   ┌─────────────┐
│  Source  │──▶│   Build   │──▶│  Test  │──▶│ Docker image│──▶│ Registry │──▶│ Kubernetes  │
│  (Git)   │   │ npm / pkg │   │ lint + │   │  (immutable)│   │  (GHCR)  │   │ (Deployment)│
└──────────┘   └───────────┘   │  unit  │   └─────────────┘   └──────────┘   └─────────────┘
                               └────────┘
```

**Narrative (DocSync)**

1. **Source:** Commit lands on GitHub (`push` / `pull_request` to `main`).  
2. **Build:** Runner checks out code, installs deps with `npm ci`.  
3. **Test:** `npm run lint` and `npm test` gate quality.  
4. **Docker image:** Multi-stage build produces a production image.  
5. **Registry:** Image pushed to **GHCR** with tags/digest from metadata action.  
6. **Kubernetes:** Cluster pulls the image; `Deployment` rolls out replicas; `Service` routes traffic (see `k8s/`).

---

## Validation checklist

- [ ] Can define **DevOps** in one paragraph (culture + automation + measurement).  
- [ ] Can describe **CI** vs **CD** without conflating them.  
- [ ] Can list at least **six** pipeline stages from source to verification.  
- [ ] Can explain how **DocSync** maps to the example workflow above.  
- [ ] Captured **proof artifacts** for Assignment 4.9 per `docs/proofs/README.md`.  
- [ ] Opened PR **`spr2-devops-principles`** and requested review.  

---

## Screenshots and proof placeholders

Store files under `docs/proofs/` (see checklist in [`docs/proofs/README.md`](../proofs/README.md)).

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | Feature or assignment branch visible | `docs/proofs/4.9-git-branch.png` |
| 2 | Commit created on branch | `docs/proofs/4.9-git-commit.png` |
| 3 | GitHub Pull Request (open or merged) | `docs/proofs/4.9-github-pr.png` |
| 4 | Repository **Actions** workflow run | `docs/proofs/4.9-repo-workflow.png` |
| 5 | `git log --oneline -n 5` (or similar) | `docs/proofs/4.9-git-log.png` |

> Redact tokens, internal URLs, or organization names if required by your institution.

---

## Learning outcome

After completing **Assignment 4.9 / A-02**, you can:

- Describe the **DevOps lifecycle** and why small, integrated changes reduce risk.  
- Contrast **CI** and **CD** and place each in a **delivery pipeline**.  
- Trace the **DocSync** path from **Git commit** to **container image** to **Kubernetes** using repository artifacts.  
- Identify **which tools** implement each stage in a typical cloud-native stack.  

---

## References

- *Accelerate* (Forsgren, Humble, Kim) — DORA capabilities and metrics  
- [Continuous Integration (Martin Fowler)](https://martinfowler.com/articles/continuousIntegration.html)  
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)  
- Repository: `README.md`, `docs/PIPELINE.md`, `docs/PIPELINE_DESIGN.md`  
