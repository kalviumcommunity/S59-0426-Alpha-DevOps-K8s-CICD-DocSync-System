# Assignment A-20 / 4.37–4.40 — GitHub Actions CI, Docker Image Automation, Tagging, and Secure Registry Push

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Gouri  
**Branch / PR identifier:** `spr20-github-actions-docker`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment numbers** | **4.37** (GitHub Actions CI) · **4.38** (Docker automation) · **4.39** (Image tagging) · **4.40** (Secure GHCR push) |
| **Module references** | **Module 9–10** (or equivalent) — CI platforms, OCI images, registries, least-privilege tokens |
| **Objective** | Explain **GitHub Actions** for DocSync; map **CI vs image build**; document **tagging** (`latest` + commit SHA) and **`GITHUB_TOKEN`**-based **GHCR** auth; understand **triggers** and **failure handling**; cross-link [`docs/pipeline/GITHUB_ACTIONS_DOCKER_AUTOMATION.md`](../pipeline/GITHUB_ACTIONS_DOCKER_AUTOMATION.md). |

---

## GitHub Actions overview

**GitHub Actions** runs **YAML-defined workflows** on hosted **runners** (`ubuntu-latest`, etc.) in response to **events** (`push`, `pull_request`, …). Each workflow contains **jobs** (parallel units) made of **steps** (sequential commands or marketplace **actions**).

---

## CI workflow purpose

| Goal | Mechanism in DocSync |
|------|----------------------|
| **Fast feedback** | Run **lint** + **tests** on every PR targeting `main` |
| **Merge confidence** | Green checks before human review completes |
| **Gate packaging** | **Docker build** runs only after CI passes **and** event is **`push` to `main`** |

---

## Build automation

| Topic | Detail |
|-------|--------|
| **What** | `docker/build-push-action` builds the **Dockerfile** context into an OCI image |
| **When** | After successful **`ci`** job, **push to `main` only** |
| **Output** | Image layers pushed to **GHCR** with labels from `docker/metadata-action` |

---

## Test automation

| Stage | Command | Failure signal |
|-------|---------|----------------|
| **Lint** | `npm run lint` | Non-zero exit → job failure |
| **Test** | `npm test` | Non-zero exit → job failure |

---

## Docker image automation

- **Immutable artifact:** each successful `main` build produces an addressable **digest**.  
- **Registry:** images land under **`ghcr.io/<owner>/<repo>`** (derived from `${{ github.repository }}`).

---

## Image tagging strategy

| Tag | Purpose |
|-----|---------|
| **`latest`** | Convenience pointer to newest **`main`** build (mutable tag) |
| **Short commit SHA** | Ties image to exact **Git** revision for audits and rollbacks |

Configured via `docker/metadata-action` in **`.github/workflows/ci-cd.yml`**.

---

## Secure registry push using GHCR

| Control | Implementation |
|---------|------------------|
| **Authentication** | `docker/login-action` with **`secrets.GITHUB_TOKEN`** |
| **Authorization** | Job permission **`packages: write`** (narrow scope) |
| **No PAT in repo** | Avoid long-lived personal tokens in YAML |

---

## GitHub secrets / `GITHUB_TOKEN` explanation

| Secret | Role |
|--------|------|
| **`GITHUB_TOKEN`** | **Ephemeral** token auto-injected per job; scoped to this repository run |
| **Repository secrets** | Optional values (e.g. future deploy keys); **never** commit plaintext |

**Optional CD:** repository secret **`KUBECONFIG_B64`** (base64 kubeconfig) enables **live** `kubectl` in the deploy job; if unset, the job prints **scaffold** instructions only.

---

## Workflow trigger explanation

| Event | `ci` | `build-and-push` | `deploy-and-verify` |
|-------|------|------------------|----------------------|
| **`pull_request`** → `main` | Runs | Skipped | Skipped |
| **`push`** → `main` | Runs | Runs | Runs |

---

## How this completes Source → Image → Registry flow

```text
git push / PR
  → Checkout (source of truth = commit SHA)
  → npm ci + lint + test        (CI)
  → docker build + push        (main only)
  → GHCR stores digest + tags   (Registry)
  → (optional) kubectl apply    (Kubernetes — when kubeconfig secret configured)
```

---

## Failure handling in CI

| Failure | System response |
|---------|------------------|
| Lint | PR checks **red**; fix locally with `npm run lint` |
| Test | Same; debug with `npm test` |
| Docker build | **No push**; inspect Dockerfile + build logs |
| GHCR login | Verify `permissions.packages: write` on job |

---

## Validation checklist

- [ ] Read **`.github/workflows/ci-cd.yml`** end-to-end (no secrets in logs)  
- [ ] Opened **Actions** run for **`DocSync CI/CD Pipeline`** on `main`  
- [ ] Confirmed **GHCR** package receives **`latest`** + **SHA** tags  
- [ ] Captured proofs for **4.37–4.40** in `docs/proofs/README.md`  
- [ ] Opened PR **`spr20-github-actions-docker`** for review  

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | Workflow YAML (editor) | `docs/proofs/4.37-workflow-yaml.png` |
| 2 | Successful Actions run | `docs/proofs/4.37-actions-success.png` |
| 3 | Lint + test job log | `docs/proofs/4.37-ci-lint-test.png` |
| 4 | Docker build/push job | `docs/proofs/4.38-docker-build-push.png` |
| 5 | GHCR package page | `docs/proofs/4.40-ghcr-package.png` |
| 6 | Image tags (UI or `docker buildx imagetools inspect`) | `docs/proofs/4.39-image-tags.png` |

---

## Learning outcome

After **Assignments 4.37–4.40 / A-20**, you can:

- Configure **event-gated** CI and **main-only** image publication  
- Explain why **`GITHUB_TOKEN`** is preferred over committed PATs for GHCR in class repos  
- Interpret **multi-tag** metadata for traceability  

---

## References

| Document | Role |
|----------|------|
| [`docs/pipeline/GITHUB_ACTIONS_DOCKER_AUTOMATION.md`](../pipeline/GITHUB_ACTIONS_DOCKER_AUTOMATION.md) | Deep reference for this PR |
| [`docs/pipeline/PIPELINE_STAGES.md`](../pipeline/PIPELINE_STAGES.md) | Stage table & job mapping |
| [GitHub Actions docs](https://docs.github.com/en/actions) | Upstream reference |
