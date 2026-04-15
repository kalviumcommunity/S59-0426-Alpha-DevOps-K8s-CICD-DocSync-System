# PIPELINE_DESIGN.md — DocSync CI/CD Stage Design

This document defines the **7-stage pipeline** for DocSync, explicitly separating CI (validation) from CD (delivery), and explaining why each stage exists and what risk it prevents.

---

## The 7 Pipeline Stages at a Glance

```
 ┌─────────────────────────────────────────────────────────────────────────────────┐
 │                                                                                 │
 │  ╔═══════════════════════════════════════════════════════════════════════════╗   │
 │  ║                CI — CONTINUOUS INTEGRATION                              ║   │
 │  ║                Goal: VALIDATION                                         ║   │
 │  ║  "Is this code correct, clean, and safe to turn into an artifact?"      ║   │
 │  ║                                                                         ║   │
 │  ║  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────┐ ║   │
 │  ║  │ Stage 1  │──▶│ Stage 2  │──▶│ Stage 3  │──▶│ Stage 4  │──▶│St. 5 │ ║   │
 │  ║  │ SOURCE / │   │ LINT /   │   │  UNIT    │   │ BUILD &  │   │PUSH  │ ║   │
 │  ║  │ CHECKOUT │   │ STATIC   │   │ TESTING  │   │ PACKAGE  │   │IMAGE │ ║   │
 │  ║  └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────┘ ║   │
 │  ║                                                                         ║   │
 │  ╚═══════════════════════════════════════════════════════════╤═════════════╝   │
 │                                                              │                  │
 │                          ★ ARTIFACT HANDOFF ★                │                  │
 │              Docker Image passes from CI to CD               │                  │
 │                                                              │                  │
 │  ╔═══════════════════════════════════════════════════════════╧═════════════╗   │
 │  ║                CD — CONTINUOUS DEPLOYMENT                              ║   │
 │  ║                Goal: DELIVERY                                          ║   │
 │  ║  "How do we safely get this validated artifact into production?"       ║   │
 │  ║                                                                         ║   │
 │  ║  ┌───────────────────────┐          ┌───────────────────────┐          ║   │
 │  ║  │       Stage 6         │─────────▶│       Stage 7         │          ║   │
 │  ║  │     DEPLOYMENT        │          │     VERIFICATION      │          ║   │
 │  ║  │ (Update K8s cluster)  │          │ (Post-deploy checks)  │          ║   │
 │  ║  └───────────────────────┘          └───────────────────────┘          ║   │
 │  ║                                                                         ║   │
 │  ╚═════════════════════════════════════════════════════════════════════════╝   │
 │                                                                                 │
 └─────────────────────────────────────────────────────────────────────────────────┘
```

---

## CI — Continuous Integration (Stages 1–5)

**Goal: Validation** — CI answers the question: *"Is this code correct, clean, and safe to turn into an artifact?"*

CI runs on **every push and every Pull Request**. Its job is to catch problems before code is merged or packaged. If any CI stage fails, the pipeline halts — no image is built, no deployment happens.

---

### Stage 1: Source / Checkout

```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

**Why it exists:** The pipeline needs the exact source code that triggered it. This stage clones the repository at the precise commit SHA that was pushed, ensuring the pipeline validates the right version of code — not a newer or older commit that someone else pushed moments before.

**Risk it mitigates:** Without checkout pinning, a race condition could cause the pipeline to test commit `A` but build commit `B`, meaning untested code gets packaged into the artifact. This stage guarantees a 1:1 relationship between "what was tested" and "what gets built."

---

### Stage 2: Lint / Static Analysis

```yaml
- name: Run linter (ESLint quality gate)
  run: npm run lint
```

**Why it exists:** Linting enforces code style rules and catches entire categories of bugs through static analysis — before a single line of code runs. ESLint flags unused variables, missing `const` declarations, accidental `==` instead of `===`, and other issues that are easy to write but hard to spot in review.

**Risk it mitigates:** The Lint stage prevents syntax errors, style inconsistencies, and common JavaScript anti-patterns from entering the codebase. Without it, these issues slip into the build stage or — worse — into production, where a subtle type coercion bug might corrupt document data. Catching these statically is orders of magnitude cheaper than debugging them in production.

**Pipeline behavior on failure:** Full stop. The PR is blocked. No image is built. The developer must fix the linting errors and push a corrected commit.

---

### Stage 3: Unit Testing

```yaml
- name: Run unit tests
  run: npm test
```

**Why it exists:** Unit tests prove that the application logic works correctly in isolation. For DocSync, this means 8 tests covering document creation, retrieval, updating with version control, conflict detection (rejecting stale writes), edit history tracking, and version-specific retrieval.

**Risk it mitigates:** The Test stage catches logic regressions — code changes that accidentally break existing functionality. For example, if a developer refactors the `update()` method and accidentally removes the version check, the test `should reject updates with wrong version` will fail immediately. Without automated tests, this regression would reach production and cause users to silently overwrite each other's work — exactly the "sync failure" problem DocSync was built to solve.

**Pipeline behavior on failure:** Full stop. This is the core safety principle: **only tested code becomes an artifact.** If tests fail, the pipeline never proceeds to build the Docker image.

---

### Stage 4: Build & Package

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v6
  with:
    context: .
    push: true
    tags: ${{ steps.meta.outputs.tags }}
```

**Why it exists:** This stage takes the validated source code and seals it into an **immutable Docker image** — a self-contained package with the application, its dependencies, the Node.js runtime, and the Alpine Linux OS. The multi-stage Dockerfile ensures only production-necessary files make it into the final image.

**Risk it mitigates:** Building a Docker image eliminates **environment drift**. Without containerization, production might run a different Node.js version, a different OS, or different dependency versions than what was tested. The image freezes all of these at build time, so the artifact that passed tests is byte-for-byte identical to what will run in production. This stage also applies image tags (Git SHA + semantic version) that create the traceability chain from production back to source code.

---

### Stage 5: Artifact Storage (Push to Registry)

```yaml
- name: Push to GHCR
  # Image is pushed as part of build-push-action with push: true
```

**Why it exists:** After the image is built and tagged, it must be stored in a **container registry** (GitHub Container Registry / GHCR) — the single source of truth for all deployable artifacts. The registry keeps every version permanently, making the full history of builds available for rollback.

**Risk it mitigates:** Without a registry, built images exist only on the CI runner, which is ephemeral — it's destroyed after the pipeline finishes. The registry ensures artifacts are durable and accessible. It also provides access control (only CI can push) and integrity verification (digests prove the image hasn't been tampered with). Kubernetes pulls exclusively from the registry; if the image isn't there, nothing can be deployed.

---

## CD — Continuous Deployment (Stages 6–7)

**Goal: Delivery** — CD answers the question: *"How do we safely get this validated artifact into production?"*

CD runs **only on pushes to `main`** (i.e., after a PR is merged). It never re-tests the code — that's CI's job. CD trusts the artifact and focuses on delivering it safely to the cluster.

---

### Stage 6: Deployment

```yaml
# Kubernetes manifest references the new image
spec:
  containers:
    - name: docsync
      image: ghcr.io/username/docsync:v1.2.0
```

```bash
kubectl apply -f k8s/deployment.yaml
```

**Why it exists:** Deployment takes the validated, tagged image from the registry and runs it in the Kubernetes cluster. The Deployment manifest is updated to reference the new image tag, and Kubernetes performs a **rolling update** — gradually replacing old Pods with new ones, ensuring zero downtime.

**Risk it mitigates:** Manual deployment (SSH → git pull → restart) is error-prone, unrepeatable, and leaves no audit trail. Declarative Kubernetes deployments are the opposite: the desired state is written in YAML, applied once, and Kubernetes handles the rest. The rolling update strategy ensures users never experience a full outage — if the new Pods fail health checks, Kubernetes automatically stops the rollout and keeps the old Pods running.

---

### Stage 7: Verification (Post-Deployment Health Checks)

```yaml
# Defined in the Deployment manifest
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 10
```

```bash
# Manual verification commands
kubectl rollout status deployment/docsync
kubectl get pods -l app=docsync
curl http://<service-ip>/health
```

**Why it exists:** Deployment alone doesn't guarantee the application is working. Verification confirms that the newly deployed containers are healthy and serving traffic. Kubernetes uses two types of probes:
- **Liveness probe** — "Is the container alive?" If it fails 3 times, K8s kills and restarts the container.
- **Readiness probe** — "Is the container ready for traffic?" If it fails, K8s removes the Pod from the Service so no requests are routed to it.

**Risk it mitigates:** Without health checks, a container could start but crash on the first request (e.g., missing environment variable, failed database connection), and Kubernetes would consider it "running" and route traffic to it. Verification ensures that only containers that pass the `/health` endpoint check receive user traffic. If a bad deploy makes it through, Kubernetes detects the failure via probes and automatically rolls back to the previous healthy version — before users are affected.

---

## Stage Ordering Logic — Why This Sequence?

Each stage is positioned to catch failures at the **cheapest possible point**. The further a bug travels down the pipeline, the more expensive it is to fix.

| # | Stage | Position Rationale |
|---|---|---|
| 1 | Source / Checkout | Must be first — everything else depends on having the code |
| 2 | Lint / Static Analysis | Runs before tests because it's faster (seconds vs. minutes) and catches syntax-level issues that would cause tests to fail anyway |
| 3 | Unit Testing | Runs after lint because it's more expensive (executes code) — no point running tests if the code has syntax errors |
| 4 | Build & Package | Runs after tests because building a Docker image takes time and resources — only validated code should be packaged |
| 5 | Artifact Storage | Runs after build because you can only push what exists — and only tested, linted, built code should enter the registry |
| 6 | Deployment | Runs after push because K8s pulls from the registry — the image must be stored before it can be deployed |
| 7 | Verification | Must be last — you can only verify what's already deployed and running |

```
 Cost to fix a bug increases →

 ┌────────┬────────┬────────┬────────┬────────┬────────┬────────┐
 │ Lint   │ Test   │ Build  │ Push   │ Deploy │ Verify │ PROD   │
 │  $     │  $$    │  $$$   │  $$$   │ $$$$   │ $$$$   │ $$$$$  │
 │ 5 sec  │ 30 sec │ 2 min  │ 1 min  │ 3 min  │ 1 min  │ ???    │
 └────────┴────────┴────────┴────────┴────────┴────────┴────────┘
   ◄── Catch bugs here (cheap, fast, automated)    Catch here (expensive, slow, user-facing) ──►
```

---

## Summary

| Aspect | CI (Stages 1–5) | CD (Stages 6–7) |
|---|---|---|
| **Goal** | Validation | Delivery |
| **Question** | "Is this code safe to merge and package?" | "How do we safely run this in production?" |
| **Triggers** | Every push + every PR | Only push to `main` (merged PR) |
| **Output** | Pass/fail + Docker image in registry | Running containers in Kubernetes |
| **On failure** | PR blocked, no image built | Kubernetes auto-rollback to previous version |
| **Who owns it** | CI Pipeline (GitHub Actions) | CD Pipeline + Infrastructure (K8s) |
