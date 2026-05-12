# DocSync — CI/CD pipeline stages (reference)

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Workflow:** `.github/workflows/ci-cd.yml` (`DocSync CI/CD Pipeline`)  
**Companion narrative:** [`../PIPELINE_DESIGN.md`](../PIPELINE_DESIGN.md)  

This document is the **tabular** source of truth for **stage purpose**, **tooling**, **I/O**, **failure handling**, and **production** notes. It aligns with the **seven headline stages** in the workflow comments while splitting some **logical** steps (for example, **install** vs **lint**) for teaching clarity.

---

## Full pipeline stage table

| # | Stage | Purpose | Tools / automation | Primary inputs | Primary outputs | Failure handling | Production-readiness notes |
|---|--------|---------|-------------------|----------------|-----------------|------------------|----------------------------|
| 1 | **Source / checkout** | Pin the workspace to the **triggering commit** | `actions/checkout@v4` | Git ref + token | Source tree at `${{ github.sha }}` | Step fails → entire job fails; rerun workflow | Use **immutable SHAs** for audits; tag releases for humans |
| 2 | **Environment verification** | Fail fast if required tools/files missing | Shell in `ci` job (`node`, `npm`, `docker`, `git`, file checks) | Workflow default image | Console log + exit **0** | Missing Dockerfile / `package.json` → **exit 1** | Extend with `cosign` / `syft` when hardening supply chain |
| 3 | **Install dependencies** | **Reproducible** Node dependencies | `actions/setup-node@v4` + `npm ci` | `package-lock.json` | `node_modules/` | Lockfile drift → `npm ci` fails → **block PR** | Prefer **`npm ci`** over `npm install` in CI |
| 4 | **Lint / static analysis** | Catch style & static bugs before runtime | `npm run lint` (ESLint) | Source + config | Pass/fail exit code | Non-zero → **PR checks red**; no image job | Add **typecheck** / **format check** if adopting TS/stricter gates |
| 5 | **Unit test** | Validate application logic | `npm test` | Source + tests | Pass/fail + coverage (if configured) | Non-zero → **block** merge signal | Keep tests **fast**; split integration tests if needed |
| 6 | **Docker image build** | Produce **immutable** OCI artifact | `docker/build-push-action` + Dockerfile context | Source, `Dockerfile`, `.dockerignore` | Image layers locally then pushed | Build failure → **no push**; digest not published | Multi-stage builds, non-root user, **pinned base** digests |
| 7 | **Registry authentication** | Authorize push to **GHCR** | `docker/login-action` + `GITHUB_TOKEN` | `permissions.packages: write` | Authenticated session | Auth failure → push fails | Use **least-privilege** tokens; OIDC where available |
| 8 | **Registry push & tagging** | Publish image + **labels/tags** | `docker/metadata-action` + push-enabled build | Registry URL, semver/git SHA | Tags + **digest** in GHCR | Push/network flake → retry policies / human rerun | Immutably reference **`@sha256:`** in Kubernetes for prod |
| 9 | **Artifact acknowledgment** | Record provenance in CI summary | `GITHUB_STEP_SUMMARY` echo | Tags + digest strings | Human-readable summary | Informational only | Attach **SBOM** / **SLSA** metadata as maturity grows |
| 10 | **Deployment** | Apply **desired cluster state** with new image | *Designed:* `kubectl apply` (manifests under `k8s/`) | Kubeconfig, image tag/digest | Reconciled Deployment | Apply/validation errors → **stop** CD; keep last revision | GitOps (Flux/Argo), **canary**, manual approval gates |
| 11 | **Verification** | Prove workload healthy post-change | *Designed:* `kubectl rollout status`, `/health`, log tail | Cluster API + Service VIP | Green checks in monitoring | Probe/HTTP failures → alert + **rollback** | Synthetic checks + **SLIs** beyond single `/health` |
| 12 | **Rollback / recovery** | Restore last known good | *Operational:* `kubectl rollout undo`, Git revert, GitOps sync | Previous digest + manifests | Stable traffic path | Human + runbook until automated guardrails exist | Automate **verify → auto-undo** only after observability trust |

> **Note:** Rows **10–12** are **scaffolded** in the current workflow (echo/documentation) until a secure, non-interactive **`kubectl`** credential is available for this course environment.

---

## Job mapping (GitHub Actions)

| Workflow job | Typical rows covered |
|--------------|----------------------|
| **`ci`** | 1–5 |
| **`build-and-push`** | 1, 6–9 (checkout repeated for isolation) |
| **`deploy-and-verify`** | 10–11 (documented today) |

**Triggers**

| Event | `ci` | `build-and-push` | `deploy-and-verify` |
|-------|------|--------------------|------------------------|
| `pull_request` → `main` | Yes | No | No |
| `push` → `main` | Yes | Yes | Yes |

---

## Production-readiness cross-check

| Concern | Recommendation |
|---------|------------------|
| **Secrets** | GitHub **Environments** + protected reviewers for prod kubeconfig |
| **Promotion** | Separate **dev/stage/prod** image tags; block `:latest` in prod if policy requires |
| **Observability** | Central logs/metrics for **pipeline** and **runtime** |
| **Rollback** | One-click **undo** tied to digest + manifest revision ID |

---

## Related files

| Path | Role |
|------|------|
| [`../assignments/A-19-cicd-pipeline-stages.md`](../assignments/A-19-cicd-pipeline-stages.md) | Assignment **4.36 / A-19** narrative |
| [`../PIPELINE_DESIGN.md`](../PIPELINE_DESIGN.md) | Deep-dive rationale per headline stage |
| [`../../.github/workflows/ci-cd.yml`](../../.github/workflows/ci-cd.yml) | Executable pipeline definition |
