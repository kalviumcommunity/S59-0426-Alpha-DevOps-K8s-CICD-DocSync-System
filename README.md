# DocSync: Real-Time Document Editing Service

> **TL;DR:** Every code change is automatically tested, sealed into an immutable Docker image, stored in a versioned registry, and deployed to Kubernetes. The same image that passes CI is the exact image that runs in production — no exceptions.

## From Git Commit to Running Container — The Artifact Flow

This project implements a **Source → Image → Registry → Cluster** deployment workflow for a real-time document editing service called **DocSync**. Every code change follows an immutable artifact pipeline: code is never deployed directly. Instead, it is packaged into a versioned Docker image, stored in a registry, and pulled by Kubernetes — guaranteeing that the exact same binary runs in every environment.

### Why This Matters

Traditional deployment (SSH into a server, `git pull`, `npm install`) introduces three variables that can silently differ between environments: **OS packages**, **dependency versions**, and **runtime configuration**. Docker eliminates all three by freezing them into a single artifact at build time.

---

## Table of Contents

- [The Problem](#the-problem)
- [The Solution: Immutable Artifact Flow](#the-solution-immutable-artifact-flow)
- [Artifact Flow Diagram](#artifact-flow-diagram)
- [How a Git Commit Becomes a Running Container](#how-a-git-commit-becomes-a-running-container)
- [Key Technical Terms](#key-technical-terms)
- [The Big Three Domains](#the-big-three-domains)
- [Responsibility Matrix](#responsibility-matrix)
- [CI vs. CD — Two Different Questions](#ci-vs-cd--two-different-questions)
- [Responsibility Flow Diagram](#responsibility-flow-diagram)
- [Reflection: Why Separation of Concerns Makes Deployment Safe](#reflection-why-separation-of-concerns-makes-deployment-safe)
- [Project Structure](#project-structure)
- [Local Development](#local-development)
- [CI/CD Pipeline](#cicd-pipeline)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Production Bug Handling: Identify → Trace → Rollback](#production-bug-handling-identify--trace--rollback)
- [Why Immutable Artifacts Beat Raw Code Deployment](#why-immutable-artifacts-beat-raw-code-deployment)

---

## The Problem

DocSync, our real-time document editing service, was suffering from three critical issues:

| Issue | Impact |
|---|---|
| **Version Conflicts / Sync Failures** | Users lost work when mismatched service versions handled concurrent edits differently |
| **Environment Drift** | Developers couldn't reproduce production bugs because local environments differed from cloud infrastructure (different Node.js versions, OS libraries, dependency trees) |
| **No Traceability** | When a bug appeared in production, there was no reliable way to determine which code change introduced it |

These problems share a single root cause: **the code running in production was not guaranteed to be identical to what was tested.**

---

## The Solution: Immutable Artifact Flow

The artifact flow model solves all three problems by enforcing one rule: **nothing reaches the cluster unless it has been sealed into an immutable Docker image.**

```
Developer pushes code
        ↓
   Git Commit / PR triggers CI
        ↓
   CI runs tests → builds Docker image
        ↓
   Image is tagged (e.g., v1.2.0) and pushed to Registry
        ↓
   Kubernetes pulls the exact image and runs it
```

This means:
- **No drift** — the image that passed CI is *byte-for-byte identical* to what runs in production.
- **Full traceability** — every image tag maps to a specific Git commit SHA.
- **Instant rollbacks** — revert to a previous image tag in seconds.

---

## Artifact Flow Diagram

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│             │     │                  │     │                 │     │                  │     │                     │
│  SOURCE     │────▶│   CI PIPELINE    │────▶│  DOCKER IMAGE   │────▶│    REGISTRY      │────▶│  K8s CLUSTER        │
│  (Git)      │     │  (GitHub Actions)│     │  (Immutable)    │     │  (GHCR/DockerHub)│     │  (Production)       │
│             │     │                  │     │                 │     │                  │     │                     │
└─────────────┘     └──────────────────┘     └─────────────────┘     └──────────────────┘     └─────────────────────┘
       │                     │                       │                        │                        │
       │                     │                       │                        │                        │
  Developer            Automated                Sealed                  Versioned               Runs identical
  pushes code       testing + build           package with             store with               container from
  or opens PR       on every commit          app + deps + OS         tags & digests             the exact image
```

### Detailed Step-by-Step Flow

```
  ┌──────────────────────────────────────────────────────────────────────┐
  │                        ARTIFACT FLOW                                │
  │                                                                      │
  │   1. COMMIT          2. CI/CD             3. BUILD                  │
  │   ┌─────────┐       ┌──────────┐        ┌──────────────┐           │
  │   │ git push│──────▶│ GitHub   │───────▶│  docker build │           │
  │   │ or PR   │       │ Actions  │        │  docker push  │           │
  │   └─────────┘       │          │        └──────┬───────┘           │
  │                     │ • lint   │               │                    │
  │                     │ • test   │               │                    │
  │                     │ • build  │               ▼                    │
  │                     └──────────┘        ┌──────────────┐           │
  │                                         │   Registry   │           │
  │   5. RUNNING         4. DEPLOY          │  (GHCR)      │           │
  │   ┌──────────┐      ┌──────────┐       │              │           │
  │   │Container │◀─────│ kubectl  │◀──────│ Tagged Image │           │
  │   │ in Pod   │      │ apply    │       │ e.g. v1.2.0  │           │
  │   └──────────┘      └──────────┘       └──────────────┘           │
  │                                                                      │
  └──────────────────────────────────────────────────────────────────────┘
```

---

## How a Git Commit Becomes a Running Container

Here is the exact journey, step by step:

### Step 1: Developer Pushes Code (Source)

A developer commits a bug fix or feature to the `main` branch or opens a Pull Request. This commit has a unique SHA hash (e.g., `a1b2c3d`) that permanently identifies the change.

```bash
git add .
git commit -m "fix: resolve document merge conflict in real-time sync"
git push origin main
```

### Step 2: CI Pipeline Triggers (GitHub Actions)

The push event triggers the GitHub Actions workflow defined in `.github/workflows/ci-cd.yml`. The pipeline:

1. **Checks out** the exact commit.
2. **Installs dependencies** in an isolated runner.
3. **Runs linting and tests** to catch regressions.
4. **Builds the Docker image** using the `Dockerfile`.
5. **Tags the image** with the Git SHA and semantic version.
6. **Pushes the image** to GitHub Container Registry (GHCR).

### Step 3: Docker Image Is Built (Immutable Artifact)

The `Dockerfile` packages the application along with its exact dependencies and runtime into a single image. Once built, this image is **immutable** — it cannot be modified, only replaced by a new build.

```bash
docker build -t ghcr.io/username/docsync:v1.2.0 .
docker build -t ghcr.io/username/docsync:a1b2c3d .
```

### Step 4: Image Is Pushed to Registry (Source of Truth)

The tagged image is pushed to the container registry, which acts as the **single source of truth** for all deployable artifacts. Kubernetes will only ever pull images from this registry.

```bash
docker push ghcr.io/username/docsync:v1.2.0
docker push ghcr.io/username/docsync:a1b2c3d
```

### Step 5: Kubernetes Pulls and Deploys (Cluster)

The Kubernetes Deployment manifest references the exact image tag. When applied, K8s pulls the image from the registry and runs it as containers inside Pods.

```yaml
spec:
  containers:
    - name: docsync
      image: ghcr.io/username/docsync:v1.2.0
```

---

## Key Technical Terms

### Image Tags

A **tag** is a human-readable label attached to a Docker image. Tags make it easy to identify and select specific versions.

| Tag | Purpose |
|---|---|
| `v1.2.0` | Semantic version — indicates a specific release |
| `latest` | Points to the most recent build (mutable — can change) |
| `a1b2c3d` | Git SHA tag — ties the image directly to a commit |

**Important:** Tags are *mutable* — the `latest` tag, for example, is simply a pointer that gets reassigned with every new push. This is why production deployments should prefer digests or pinned version tags.

### Image Digests

A **digest** is a cryptographic hash (SHA-256) of the image's contents. Unlike tags, a digest is **immutable and unique** — it is the "fingerprint" of the exact bytes in the image.

```
ghcr.io/username/docsync@sha256:3e7a89c1f2d4b5a6e8c9d0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1
```

**Why digests matter:**
- A tag like `v1.2.0` *could* theoretically be reassigned to a different image. A digest cannot.
- For maximum security and reproducibility, Kubernetes manifests can reference images by digest instead of tag.
- Digests provide cryptographic proof that the image has not been tampered with.

### Container Registries

A **registry** is a versioned storage service for Docker images. It functions as the **source of truth** for Kubernetes because:

1. **Kubernetes only pulls from registries** — it never builds images itself.
2. **Registries store every version** — enabling instant rollbacks by re-deploying a previous tag.
3. **Registries provide access control** — ensuring only authorized images enter the cluster.
4. **Registries verify integrity** — using digests to confirm images haven't been corrupted.

**Tag vs. Digest — Quick Comparison:**

| Property | Tag (e.g. `v1.2.0`) | Digest (e.g. `sha256:3e7a...`) |
|---|---|---|
| Human-readable | Yes | No |
| Mutable | Yes — can be reassigned | No — cryptographically fixed |
| Use case | Convenient version selection | Verification & auditability |
| Production-safe | Only if pinned | Always |

Common registries:
- **Docker Hub** — public default registry
- **GitHub Container Registry (GHCR)** — integrated with GitHub Actions
- **Amazon ECR / Google GCR / Azure ACR** — cloud-provider managed registries

---

## The Big Three Domains

Every production system is governed by three distinct domains. Each has a clear role, and blurring the lines between them is where outages are born.

### 1. Application Code — Logic + Unit Tests

The application code is the **what** — the business logic that solves user problems. For DocSync, this is the Express server, the WebSocket real-time sync layer, and the `DocumentStore` with version-conflict detection.

**Responsibilities:**
- Implement features and business rules (document CRUD, conflict resolution, version history).
- Include unit tests that prove the logic works in isolation (`tests/document.test.js`).
- Define its own dependencies (`package.json`) but **never** decide how or where it gets deployed.

Application code knows nothing about Docker, Kubernetes, or registries. It doesn't know if it's running on a developer's laptop or a 50-node production cluster — and that's by design. This separation means developers can focus entirely on correctness without worrying about infrastructure.

### 2. The Pipeline (CI/CD) — Orchestration + Validation

The pipeline is the **gatekeeper** — the automated system that decides whether code is safe to merge and how it reaches production. In DocSync, this is the GitHub Actions workflow (`.github/workflows/ci-cd.yml`).

**Responsibilities:**
- **CI (Continuous Integration):** Run linting, execute unit tests, and build the Docker image. If any step fails, the pipeline halts and the code never becomes an artifact.
- **CD (Continuous Deployment):** Tag the image with the Git SHA and semantic version, push it to the container registry, and update the Kubernetes deployment to reference the new image.
- Enforce quality gates — no human should manually decide "this is ready." The pipeline's pass/fail is the single source of truth.

The pipeline never contains business logic. It doesn't know what a "document" is. It only knows: "Did the tests pass? Then build and ship."

### 3. Infrastructure (Kubernetes) — Execution + Health

Infrastructure is the **where and how** — the runtime platform that takes a sealed image and keeps it running reliably. In DocSync, this is Kubernetes via the manifests in `k8s/`.

**Responsibilities:**
- Pull the exact image specified in the Deployment manifest from the registry.
- Run the specified number of replicas (3 Pods for DocSync) across the cluster.
- **Self-heal:** If a container crashes, Kubernetes automatically restarts it. If a node fails, it reschedules Pods to healthy nodes.
- Manage rolling updates: gradually replace old Pods with new ones during a deployment, ensuring zero downtime.
- Enforce resource limits (CPU, memory) and run health checks (liveness/readiness probes).

Kubernetes never builds images, runs tests, or reads source code. It only cares about one thing: "Here's an image — keep it running."

---

## Responsibility Matrix

This table maps every action in the deployment lifecycle to its owner. No action should have ambiguous ownership.

| Action | Owner | Why This Owner? |
|---|---|---|
| Writing application logic | **Application Code** | Developers own feature implementation |
| Writing & maintaining unit tests | **Application Code** | Tests validate business logic, not infrastructure |
| Running unit tests | **CI Pipeline** | Automated execution on every commit ensures consistency |
| Running linter/static analysis | **CI Pipeline** | Code quality checks are a merge prerequisite |
| Building the Docker image | **CI Pipeline** | Only CI has the authority to create deployable artifacts |
| Tagging images (SHA + semver) | **CI Pipeline** | Tags must map 1:1 to tested commits — manual tagging is error-prone |
| Pushing images to the registry | **CI Pipeline** | CI authenticates with the registry; developers don't push images directly |
| Updating Kubernetes manifests | **CD Pipeline** | Deployment configuration is updated after a validated artifact exists |
| Applying manifests to the cluster | **CD Pipeline** | Automated deployment ensures the correct image reaches the cluster |
| Running containers from images | **Infrastructure (K8s)** | K8s pulls the image and manages container lifecycle |
| Self-healing (restarting crashed containers) | **Infrastructure (K8s)** | K8s monitors Pod health and restarts failures automatically |
| Scaling replicas up/down | **Infrastructure (K8s)** | K8s responds to load or manual scaling commands |
| Rolling updates & rollbacks | **Infrastructure (K8s)** | K8s manages zero-downtime replacements using its rollout strategy |
| Health checks (liveness/readiness) | **Infrastructure (K8s)** | Probes are defined in manifests but executed and enforced by K8s |

---

## CI vs. CD — Two Different Questions

CI and CD are often grouped together, but they ask fundamentally different questions and serve different purposes.

### CI asks: "Is this code safe to merge?"

Continuous Integration runs **before** code enters the main branch. Its job is to catch problems early:

- Does the code compile/parse without errors?
- Do all unit tests pass?
- Does the linter flag any style or quality issues?
- Can a Docker image be built successfully from this code?

If any answer is "no," the PR is blocked. CI protects the codebase from broken commits. It is a **pre-merge** gate.

```
Pull Request opened
       ↓
  ┌─────────────┐
  │   CI asks:   │
  │ "Safe to     │──── NO ──→ PR blocked, developer fixes code
  │  merge?"     │
  └──────┬──────┘
         │ YES
         ↓
   Code merges into main
```

### CD asks: "How do we safely run this in production?"

Continuous Deployment runs **after** code is merged. Its job is to get the validated artifact into the cluster safely:

- Tag the Docker image with the commit SHA and version.
- Push the image to the container registry.
- Update the Kubernetes Deployment to reference the new image.
- Use a rolling update strategy so users experience zero downtime.

CD never re-tests the code — that's CI's job. CD trusts that CI already validated the artifact and focuses entirely on safe delivery.

```
   Code merged into main
         ↓
  ┌──────────────┐
  │   CD asks:    │
  │ "How to run   │──→ Tag image → Push to registry → Update K8s manifest
  │  safely?"     │
  └──────┬───────┘
         ↓
   Rolling update in Kubernetes (zero downtime)
```

**Why the separation matters:** A developer opening a PR should never accidentally trigger a production deployment. CI validates; CD ships. By splitting them, you ensure that code review and testing happen in isolation from deployment, and a failed test can never result in broken production.

---

## Responsibility Flow Diagram

This diagram highlights the **handoff points** between CI, CD, and Infrastructure, with the critical "Artifact Handoff" where CI passes a sealed Docker image — not raw code — to CD.

```
  ┌─────────────────────────────────────────────────────────────────────────────────┐
  │                                                                                 │
  │   CODE REPOSITORY                                                               │
  │   ┌──────────────────┐                                                         │
  │   │  Developer pushes │                                                         │
  │   │  code / opens PR  │                                                         │
  │   └────────┬─────────┘                                                         │
  │            │                                                                    │
  │ ═══════════╪════════════════════════════════════════════════════════════════     │
  │  CI DOMAIN │ (Continuous Integration)                                           │
  │ ═══════════╪════════════════════════════════════════════════════════════════     │
  │            ▼                                                                    │
  │   ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐       │
  │   │  Checkout Code   │────▶│   Run Linter +   │────▶│   Build Docker   │       │
  │   │                  │     │   Unit Tests     │     │   Image          │       │
  │   └──────────────────┘     └──────────────────┘     └────────┬─────────┘       │
  │                                                              │                  │
  │                              CI output: Pass/Fail            │ Pass             │
  │                              (blocks merge if fail)          │                  │
  │                                                              ▼                  │
  │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
  │                     ★ ARTIFACT HANDOFF POINT ★                                  │
  │            CI passes a DOCKER IMAGE (not source code) to CD                     │
  │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
  │                                                              │                  │
  │ ═══════════╪════════════════════════════════════════════════╪═══════════════    │
  │  CD DOMAIN │ (Continuous Deployment)                        │                   │
  │ ═══════════╪════════════════════════════════════════════════╪═══════════════    │
  │            │                                                ▼                   │
  │            │    ┌──────────────────┐     ┌──────────────────────┐               │
  │            │    │  Tag Image with  │────▶│  Push Image to       │               │
  │            │    │  SHA + semver    │     │  Container Registry  │               │
  │            │    └──────────────────┘     └──────────┬───────────┘               │
  │            │                                       │                            │
  │            │    ┌──────────────────┐                │                            │
  │            │    │  Update K8s      │◀───────────────┘                            │
  │            │    │  Deployment YAML │                                             │
  │            │    └────────┬─────────┘                                             │
  │                          │                                                      │
  │ ═════════════════════════╪══════════════════════════════════════════════════     │
  │  INFRASTRUCTURE DOMAIN   │ (Kubernetes)                                         │
  │ ═════════════════════════╪══════════════════════════════════════════════════     │
  │                          ▼                                                      │
  │   ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐       │
  │   │  Pull Image from │────▶│  Rolling Update   │────▶│  Health Checks   │       │
  │   │  Registry        │     │  (replace Pods)   │     │  + Self-healing  │       │
  │   └──────────────────┘     └──────────────────┘     └──────────────────┘       │
  │                                                                                 │
  └─────────────────────────────────────────────────────────────────────────────────┘
```

**Key observations:**
- The boundary between CI and CD is the **Artifact Handoff** — the Docker image. CI produces it; CD consumes it. Raw source code never crosses this boundary.
- Kubernetes never interacts with the CI pipeline or the code repository. It only knows about the registry and the image reference in its manifests.
- Each domain can fail independently without cascading: a linter failure in CI doesn't crash production; a Pod crash in K8s doesn't block new PRs.

---

## Reflection: Why Separation of Concerns Makes Deployment Safe

### Why is it dangerous for application code to "deploy itself" directly?

When application code has the ability to trigger its own deployment — for example, a post-commit hook that runs `scp` to copy files to a server — you lose every safety net. There is no quality gate between "developer wrote code" and "code is live in production." A single typo in a hot-fix commit could take down the entire service because nothing verified the change first. Worse, there's no artifact to roll back to: the previous state was overwritten on the server. Self-deploying code also means that any developer with commit access effectively has unrestricted production access, which is a security and compliance risk. The pipeline exists specifically to be a neutral, automated barrier that enforces "test first, build second, deploy last."

### How does separating CI from CD enable safe Pull Request reviews?

When CI and CD are separate, a Pull Request triggers *only* CI — tests run, the linter checks style, and the build is verified. The reviewer sees a green checkmark and can focus on code quality, logic, and design without worrying about deployment consequences. The code is evaluated in isolation: "Does this change work correctly?" is answered *before* "Should we ship this?" is even asked. If CI and CD were combined into one step, merging a PR would immediately deploy to production, making code review a high-stakes gamble instead of a thoughtful process. Separation means reviewers can approve with confidence, knowing that deployment is a controlled, subsequent step with its own safeguards (rolling updates, health checks, rollback capability).

---

## Project Structure

```
S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System/
├── .github/
│   └── workflows/
│       └── ci-cd.yml            # GitHub Actions CI/CD pipeline
├── k8s/
│   ├── deployment.yaml          # Kubernetes Deployment manifest
│   └── service.yaml             # Kubernetes Service manifest
├── src/
│   ├── server.js                # Express + WebSocket server
│   └── document.js              # Document sync logic
├── tests/
│   └── document.test.js         # Unit tests
├── Dockerfile                   # Multi-stage Docker build
├── .dockerignore                # Exclude unnecessary files from image
├── package.json                 # Node.js dependencies
├── VIDEO_SCRIPT.md              # Video demonstration script
└── README.md                    # This file
```

---

## Local Development

```bash
# Install dependencies
npm install

# Run the service locally
npm start

# Run tests
npm test

# Build Docker image locally
docker build -t docsync:local .

# Run container locally
docker run -p 3000:3000 docsync:local
```

---

## CI/CD Pipeline

The GitHub Actions pipeline (`.github/workflows/ci-cd.yml`) automates the entire flow:

```
Push/PR to main
    ↓
┌─────────────────────┐
│  1. Checkout Code    │
│  2. Setup Node.js    │
│  3. Install Deps     │
│  4. Run Linter       │
│  5. Run Tests        │
├─────────────────────┤
│  6. Build Image      │
│  7. Tag with SHA     │
│     + semver         │
│  8. Push to GHCR     │
├─────────────────────┤
│  9. Update K8s       │
│     deployment       │
└─────────────────────┘
```

Key features:
- Runs on every push to `main` and every Pull Request.
- Fails fast: if tests fail, the image is never built.
- Tags images with both the Git SHA (for traceability) and semantic version (for human readability).

---

## Kubernetes Deployment

The `k8s/` directory contains the manifests needed to deploy DocSync:

- **`deployment.yaml`** — Defines the Pod template with the exact image reference, resource limits, health checks, and rolling update strategy.
- **`service.yaml`** — Exposes the deployment internally via a ClusterIP service (or LoadBalancer for external access).

### Deploy to a cluster:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Verify the deployment
kubectl get pods -l app=docsync
kubectl describe deployment docsync
```

---

## Production Bug Handling: Identify → Trace → Rollback

When a bug is discovered in production, the artifact flow gives us a clear, three-step remediation process:

### 1. Identify — What image is running?

```bash
# Check which image the current deployment is using
kubectl get deployment docsync -o jsonpath='{.spec.template.spec.containers[0].image}'
# Output: ghcr.io/username/docsync:v1.2.0

# Get the image digest for absolute certainty
kubectl get pods -l app=docsync -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
# Output: ghcr.io/username/docsync@sha256:3e7a89c1f2d4...
```

### 2. Trace — Which commit built this image?

Since the CI pipeline tags every image with the Git commit SHA:

```bash
# The image tag IS the commit reference
# ghcr.io/username/docsync:a1b2c3d → git commit a1b2c3d

# View the exact changes in that commit
git log a1b2c3d -1 --stat
git show a1b2c3d
```

This lets you pinpoint the exact lines of code that introduced the bug.

### 3. Rollback — Revert to the last stable version

```bash
# Option A: Use kubectl to set the image to the previous stable version
kubectl set image deployment/docsync docsync=ghcr.io/username/docsync:v1.1.0

# Option B: Roll back to the previous deployment revision
kubectl rollout undo deployment/docsync

# Verify the rollback succeeded
kubectl rollout status deployment/docsync
kubectl get pods -l app=docsync
```

The rollback is **instant** because:
- The previous image (`v1.1.0`) is still in the registry — nothing was deleted.
- Kubernetes simply pulls the old image and creates new Pods with it.
- No rebuilding, no redeploying from source, no guessing.

---

## Why Immutable Artifacts Beat Raw Code Deployment

Deploying raw code (e.g., running `git pull` on a server followed by `npm install`) is fundamentally fragile. Here's why the immutable artifact model is superior:

**Consistency across environments.** A Docker image bundles the application code, its dependencies, the runtime, and even OS-level libraries into a single sealed package. When QA approves an image on staging, the *exact same bytes* are promoted to production. There is zero chance of "it works on my machine" discrepancies because the image *is* the machine.

**Safe, instant rollbacks.** In a raw-code deployment, rolling back means reverting Git commits, re-running `npm install` (which might resolve to different dependency versions), and praying the server state is clean. With images, rollback is a single command: point the deployment to a previous tag. The old image is already built, tested, and waiting in the registry.

**Auditability and traceability.** Every image in the registry is tagged with a Git SHA. This creates an unbroken chain: `production Pod → image tag → Git commit → code diff → developer`. When a user reports a bug, you can trace it to the exact line of code in minutes, not hours.

**Security and integrity.** Images are verified via cryptographic digests. You can prove that the image running in production has not been tampered with since it was built by CI. Raw code deployments offer no such guarantee.

**Parallel, zero-downtime deployments.** Kubernetes uses a rolling update strategy: it spins up new Pods with the updated image alongside the old ones, shifts traffic gradually, and only terminates old Pods once the new ones are healthy. If anything goes wrong, it automatically rolls back. This is only possible because images are self-contained and stateless.

In short, immutable artifacts transform deployment from a risky, manual process into a deterministic, automated, and reversible operation. For a service like DocSync — where users depend on data integrity in real time — this isn't just best practice; it's a requirement.

---

---

## AI Enhancement Log

This documentation was iteratively refined using AI (Claude) to improve clarity, accuracy, and structure. The process:

1. **Initial Draft** — Written with technical explanations of the artifact flow, key terms, and the case study.
2. **AI Review Request** — Submitted the draft to Claude with the prompt:  
   *"Review this README for a DevOps project explaining the Source → Image → Registry → Cluster workflow. Suggest improvements for clarity, completeness, and technical accuracy."*
3. **Improvements Applied:**
   - Added a comparison table in the Problem section for clearer impact visualization.
   - Expanded the Tag vs. Digest explanation with a concrete example of why mutable tags are risky.
   - Strengthened the "Why Immutable Artifacts" reflection with five specific dimensions (consistency, rollbacks, auditability, security, zero-downtime).
   - Added the step-by-step detailed flow diagram alongside the high-level overview.
   - Included `kubectl` commands with expected output in the bug-handling section for practical realism.
4. **Final Review** — Re-checked all technical claims and command syntax for accuracy.

This improvement process is visible in the PR commit history as separate commits.
