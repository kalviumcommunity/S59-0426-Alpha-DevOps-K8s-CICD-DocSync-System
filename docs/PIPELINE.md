# PIPELINE.md — DocSync Delivery Flow

This document explains **every stage** of the DocSync CI/CD pipeline, from a developer's `git push` to a running container in Kubernetes.

---

## Pipeline Overview

```
  Developer pushes code
          │
          ▼
  ┌───────────────────────────────────────────────────┐
  │              CI — CONTINUOUS INTEGRATION           │
  │                                                    │
  │  Stage 1: Checkout ─► Stage 2: Setup Node.js       │
  │       │                                            │
  │  Stage 3: Install Deps ─► Stage 4: Lint (ESLint)   │
  │       │                                            │
  │  Stage 5: Run Unit Tests                           │
  │       │                                            │
  │       ▼                                            │
  │  ┌──────────┐                                      │
  │  │ PASS?    │── NO ──► Pipeline fails, PR blocked  │
  │  └────┬─────┘                                      │
  │       │ YES                                        │
  └───────┼────────────────────────────────────────────┘
          │
  ─ ─ ─ ─ ─ ARTIFACT HANDOFF ─ ─ ─ ─ ─
          │
  ┌───────┼────────────────────────────────────────────┐
  │       ▼          CD — CONTINUOUS DEPLOYMENT        │
  │                                                    │
  │  Stage 6: Build Docker Image                       │
  │       │                                            │
  │  Stage 7: Tag with Git SHA + semver                │
  │       │                                            │
  │  Stage 8: Push to Container Registry (GHCR)        │
  │       │                                            │
  │  Stage 9: Update Kubernetes Deployment manifest    │
  │                                                    │
  └────────────────────────────────────────────────────┘
          │
          ▼
  ┌────────────────────────────────────────────────────┐
  │         INFRASTRUCTURE — KUBERNETES                │
  │                                                    │
  │  Pull image from registry                          │
  │  Rolling update (zero downtime)                    │
  │  Health checks + self-healing                      │
  └────────────────────────────────────────────────────┘
```

---

## Stage-by-Stage Breakdown

### Stage 1: Checkout Code

```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

**What it does:** Clones the repository at the exact commit SHA that triggered the workflow. This guarantees the pipeline works on the precise version of code the developer pushed — not some other commit that may have landed in between.

**Why it matters:** Without pinning to the triggering commit, a race condition could cause the pipeline to test one version of code and build a different one.

---

### Stage 2: Setup Node.js Runtime

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: "20"
    cache: "npm"
```

**What it does:** Installs Node.js v20 on the CI runner and enables npm caching to speed up dependency installation on subsequent runs.

**Why it matters:** Pinning the Node.js version ensures the pipeline uses the same runtime as the Dockerfile. The `cache: "npm"` flag avoids re-downloading unchanged packages, cutting pipeline time by 30–60 seconds.

---

### Stage 3: Install Dependencies

```yaml
- name: Install dependencies
  run: npm ci
```

**What it does:** Installs dependencies from `package-lock.json` exactly as specified — no version range resolution, no surprises.

**Why it matters:** `npm ci` (clean install) is stricter than `npm install`. It:
- Deletes `node_modules/` and installs from scratch.
- Fails if `package-lock.json` is out of sync with `package.json`.
- Guarantees reproducible installs across all environments.

---

### Stage 4: Run Linter (Quality Gate)

```yaml
- name: Run linter
  run: npm run lint
```

**What it does:** Runs ESLint against all source files to catch code quality issues, unused variables, missing `const`, and potential bugs.

**Why it matters:** Linting is a **quality gate** — it catches entire categories of bugs before tests even run. Enforcing style consistency also reduces cognitive load during code review, letting reviewers focus on logic instead of formatting.

**If this stage fails:** The pipeline stops. No image is built, and the PR cannot be merged. The developer must fix the linting errors and push again.

---

### Stage 5: Run Unit Tests (Quality Gate)

```yaml
- name: Run tests
  run: npm test
```

**What it does:** Executes all test files in `tests/` using Node.js built-in test runner. For DocSync, this runs 8 tests covering document creation, retrieval, updates, version conflict detection, and edit history.

**Why it matters:** Tests prove the application logic works correctly. If a developer introduces a regression — e.g., breaking the version-conflict check — this stage catches it before the code ever becomes an artifact.

**If this stage fails:** Same as linting — full stop. The pipeline will not proceed to build the Docker image. This is the core safety principle: **only tested code becomes an artifact.**

---

### Stage 6: Build Docker Image (Artifact Creation)

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v6
  with:
    context: .
    push: true
```

**What it does:** Builds a multi-stage Docker image using the `Dockerfile`:
1. **Builder stage** — Installs production dependencies in an isolated layer.
2. **Production stage** — Copies only the built artifacts into a minimal Alpine image, adds a non-root user, and configures a health check.

**Why it matters:** The Docker image is the **immutable artifact** — the sealed package that will run identically on any machine. Multi-stage builds keep the final image small (~120MB vs ~900MB with dev dependencies).

---

### Stage 7: Tag the Image

```yaml
tags: |
  type=sha,prefix=
  type=semver,pattern=v{{version}}
  type=raw,value=latest
```

**What it does:** Applies three tags to the built image:
- **Git SHA** (e.g., `a1b2c3d`) — Maps the image directly to the commit that produced it.
- **Semantic version** (e.g., `v1.2.0`) — Human-readable release version.
- **`latest`** — Convenience pointer to the most recent build.

**Why it matters:** Tags create the traceability chain. When a bug appears in production, you check the running image's tag, find the commit SHA, and pinpoint the exact code change. Without proper tagging, debugging production issues becomes guesswork.

---

### Stage 8: Push to Container Registry

**What it does:** Uploads the tagged image to GitHub Container Registry (GHCR). The registry stores every version permanently.

**Why it matters:** The registry is the **single source of truth** for Kubernetes. The cluster never builds images — it only pulls them from the registry. Storing every version means rollbacks are instant: just point the deployment to a previous tag.

---

### Stage 9: Update Kubernetes Deployment (CD)

**What it does:** Updates the image reference in the Kubernetes Deployment manifest to point to the newly built image tag. When applied, Kubernetes performs a rolling update.

**Why it matters:** This is the **only** way code reaches production — through a manifest update referencing a registry image. No SSH, no `git pull`, no manual intervention.

---

## Pre-Build Validation Script

Before triggering the full pipeline locally, developers can run:

```bash
bash scripts/pre-build-check.sh
```

This script validates:
- Node.js, npm, Docker, and Git are installed
- Docker daemon is running
- `Dockerfile` and `package.json` exist
- Test files are present in `tests/`

This catches environment issues early, before wasting time on a build that would fail.

---

## Pipeline Triggers

| Event | What Runs |
|---|---|
| Pull Request to `main` | CI only (lint + test) — no image is built |
| Push to `main` (merge) | CI + CD (lint, test, build, push, deploy) |

This separation ensures PRs are safe to review without deployment risk.

---

## Failure Modes

| Stage | If It Fails... |
|---|---|
| Lint | PR blocked. Developer fixes code style issues. |
| Test | PR blocked. Developer fixes failing tests. |
| Docker Build | Image not created. Usually a Dockerfile or dependency issue. |
| Registry Push | Image built but not stored. Retry or check auth credentials. |
| K8s Rollout | Kubernetes auto-rolls back to the previous healthy version. |

At every stage, failure is **isolated** — a lint failure doesn't crash production, and a K8s rollout failure doesn't affect the codebase.
