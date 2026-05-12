# Assignment A-11 / 4.16 — Managing Docker Images and Registries (Docker Hub / GHCR)

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr11-docker-registry-ghcr`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.16** (tracker ID: **A-11**) |
| **Module reference** | **Module 4** — Image distribution: registries, tags, authentication, and how DocSync flows from **local build → GHCR → Kubernetes** |
| **Objective** | Explain **container registries**, compare **Docker Hub vs GHCR**, document **tagging strategy** (see [`docs/registry/IMAGE_TAGGING_STRATEGY.md`](../registry/IMAGE_TAGGING_STRATEGY.md)), practice **`docker tag` / `docker login` / `docker push` / `docker pull`** with **placeholders only** for secrets, and relate registry usage to **CI/CD** and **Kubernetes**. |

---

## What is a container registry?

A **container registry** is a **remote store** for OCI/Docker images: it holds **layer blobs**, **manifests**, and **tags** that point at immutable **digests**. Runtimes (**Docker**, **containerd**, Kubernetes) **pull** by `registry/repo:tag` or by **digest** (`@sha256:…`).

---

## Docker Hub vs GHCR

| Aspect | Docker Hub | GitHub Container Registry (GHCR) |
|--------|------------|-------------------------------------|
| **Identity** | Docker ID / org | GitHub user or org |
| **Integration** | Generic CI | Native **GitHub Actions** + `GITHUB_TOKEN` / PAT |
| **Visibility** | Public/private repos | Linked to GitHub repo / packages |
| **Rate limits** | Tiered pull limits | GitHub plan / policy based |

DocSync’s pipeline in this repo is oriented toward **GHCR** (see `.github/workflows/` in a future read-only review—**do not** modify the workflow in this assignment).

---

## Why GHCR is used in this project

| Reason | Detail |
|--------|--------|
| **Same platform as source** | Permissions align with GitHub org `kalviumcommunity` |
| **CI token** | `GITHUB_TOKEN` (scoped) can push packages without Docker Hub robot accounts |
| **Audit trail** | Package version history beside commits and Actions runs |

---

## Image tagging strategy

High-level rules live in **[`docs/registry/IMAGE_TAGGING_STRATEGY.md`](../registry/IMAGE_TAGGING_STRATEGY.md)**.

| Tag type | Purpose |
|----------|---------|
| **Commit SHA** | Immutable traceability to Git |
| **Semantic version** | Human-friendly releases (`v1.2.0`) |
| **`latest`** | Convenience default; **not** sufficient alone for production |
| **Environment / lab** | e.g. `local-dev` for coursework |

---

## `latest` vs version tag vs commit SHA tag

| Tag | Mutability | Best for |
|-----|------------|----------|
| **`latest`** | Pointer may move | Demos, quick pulls |
| **`v1.2.0`** | Should be immutable per release policy | Stakeholder communication |
| **`sha-<short>`** / **digest** | Effectively immutable | Production pin, rollbacks |

---

## Secure registry login

**Never** commit tokens, `.env` files, or paste PATs into screenshots uncropped.

```bash
# Preferred: stdin (avoids shell history of raw token)
echo "$GHCR_TOKEN" | docker login ghcr.io -u <GITHUB_USERNAME> --password-stdin
```

| Secret source | Notes |
|---------------|--------|
| **`GHCR_TOKEN` env** | Short-lived **PAT** with `read:packages` + `write:packages` (principle of least privilege) |
| **`GITHUB_TOKEN` in Actions** | Scoped by workflow `permissions`; not copied into this repo |

---

## Pushing images to GHCR

After `docker login`:

```bash
docker push ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system:local
```

> **Lowercase:** Docker Engine expects **lowercase** `ghcr.io/owner/image` paths. GitHub’s Packages UI shows the canonical name—**copy from there** if unsure. A common teaching example (mixed case) maps to the lowercase path above.

---

## Pulling images from GHCR

```bash
docker pull ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system:local
```

Private packages require prior **`docker login ghcr.io`** with credentials that have **`read:packages`**.

---

## How Kubernetes uses registry images

The **`Deployment`** `Pod` template references **`spec.containers[].image`**. The kubelet instructs the container runtime to **pull** (unless `imagePullPolicy: Never` / cached) from the registry embedded in that string. DocSync’s sample manifest uses a **`ghcr.io/...`** image placeholder (see `k8s/deployment.yaml` — **not** modified in this PR).

---

## How registry usage supports CI/CD

```text
  git push main
       │
       ▼
  GitHub Actions (build + test)
       │
       ▼
  docker build / tag / push ──► GHCR (immutable digest recorded)
       │
       ▼
  CD stage applies Kubernetes with new image reference
```

The **same digest** that passed CI is the artifact clusters should run—no “SSH and git pull on the server.”

---

## Commands used

### `docker build -t docsync:local .`

Builds from the repository `Dockerfile` into a **local tag** used as the source for registry tagging.

**Expected:** successful build; image listed under `docker images`.

---

### `docker tag` (local → GHCR name)

**Canonical (lowercase) example:**

```bash
docker tag docsync:local ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system:local
```

**Course-style example (same logical package; verify casing in UI):**

```bash
docker tag docsync:local ghcr.io/kalviumcommunity/S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System:local
```

If the second form is rejected by the daemon, use the **lowercase** path from GitHub Packages.

**Expected:** second row in `docker images` with identical `IMAGE ID` as `docsync:local`.

---

### `docker login` (token hidden in docs)

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u <GITHUB_USERNAME> --password-stdin
```

**Expected:** `Login Succeeded`.

---

### `docker push`

```bash
docker push ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system:local
```

**Expected:** layer uploads, digest summary, `Pushed` / manifest listed.

---

### `docker pull`

```bash
docker pull ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system:local
```

**Expected:** `Status: Downloaded newer image` or `Image is up to date`.

---

### Helper: `scripts/docker-tag-ghcr.sh`

Builds **`docsync:local`**, applies **`docker tag`** to **`${GHCR_IMAGE}:${TAG}`** (default tag **`local-dev`**), prints **login/push/pull** next steps—**no secrets**.

```bash
chmod +x scripts/docker-tag-ghcr.sh
./scripts/docker-tag-ghcr.sh              # tag: local-dev
./scripts/docker-tag-ghcr.sh local        # custom tag: local
```

---

## Expected outputs (summary)

| Step | Pass criteria |
|------|----------------|
| Build | Exit code 0 |
| Tag | `docker images` shows GHCR-qualified name |
| Login | `Login Succeeded` (no token echoed) |
| Push | Remote digest visible on GitHub Packages |
| Pull | Image updates locally |

---

## Screenshot / proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `docker images` after tag | `docs/proofs/4.16-docker-images.png` |
| 2 | `docker tag` command + output | `docs/proofs/4.16-docker-tag.png` |
| 3 | `docker login` success (**token redacted**) | `docs/proofs/4.16-ghcr-login.png` |
| 4 | `docker push` | `docs/proofs/4.16-docker-push.png` |
| 5 | GitHub **Packages** page | `docs/proofs/4.16-ghcr-package.png` |
| 6 | `docker pull` | `docs/proofs/4.16-docker-pull.png` |

---

## Validation checklist

- [ ] Read [`docs/registry/IMAGE_TAGGING_STRATEGY.md`](../registry/IMAGE_TAGGING_STRATEGY.md)  
- [ ] Built **`docsync:local`** and tagged for **`ghcr.io/...`**  
- [ ] Logged in with **stdin** or secure helper (**no** token in git)  
- [ ] **Pushed** and verified package on GitHub  
- [ ] **Pulled** image on a clean context (or after `rmi`)  
- [ ] Captured proofs per `docs/proofs/README.md` (Assignment **4.16**)  
- [ ] Opened PR **`spr11-docker-registry-ghcr`** for review  

---

## Learning outcome

After **Assignment 4.16 / A-11**, you can:

- Contrast **Docker Hub** and **GHCR** and justify GHCR for GitHub-centric projects.  
- Apply a disciplined **tagging** model and explain **rollback** benefits.  
- Perform **login / push / pull** safely without leaking credentials.  
- Explain how **Kubernetes** consumes registry references in a `Deployment`.  

---

## References

- [GitHub Packages — GHCR](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)  
- [`docs/registry/IMAGE_TAGGING_STRATEGY.md`](../registry/IMAGE_TAGGING_STRATEGY.md)  
- [`scripts/docker-tag-ghcr.sh`](../../scripts/docker-tag-ghcr.sh)  
