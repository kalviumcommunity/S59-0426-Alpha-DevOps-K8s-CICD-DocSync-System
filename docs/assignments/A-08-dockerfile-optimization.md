# Assignment A-08 / 4.14 (optimization) — Dockerfile Optimization: Layers, Caching, Security, and Best Practices

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr8-dockerfile-optimization`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.14 (optimization track)** (tracker ID: **A-08**) |
| **Module reference** | **Module 4** — Hardening the container supply chain: multi-stage builds, minimal runtime, least-privilege execution, and observable health |
| **Objective** | Evolve the PR7 **single-stage** `Dockerfile` into a **production-oriented multi-stage** image; tighten **`.dockerignore`**; explain **caching**, **size**, **security**, **`HEALTHCHECK`**, and verify behavior with Docker CLI commands without changing application business logic. |

---

## Why Dockerfile optimization matters

| Concern | Without optimization | With optimization |
|---------|----------------------|-------------------|
| **Attack surface** | Dev tools, caches, extra packages in runtime | Final stage contains only what runs the service |
| **Supply chain** | Accidental `COPY . .` leaks secrets/docs | `.dockerignore` + explicit `COPY` paths |
| **Build speed** | Any file change invalidates dependency layer | Lockfiles copied before `src/` |
| **Operations** | Process runs as root | Dedicated UID/GID + `HEALTHCHECK` |

---

## Multi-stage build explanation

A **multi-stage** Dockerfile declares more than one `FROM`. Earlier stages may use full toolchains; the **final stage** copies only required artifacts (`node_modules`, `src/`, manifests) from the builder. Intermediate layers are **discarded** from the published image, shrinking size and reducing disclosure of build-only paths.

**DocSync layout (PR8)**

| Stage | Responsibility |
|-------|------------------|
| **`builder`** | `npm ci --omit=dev`, copy `src/` |
| **final (`node:20-alpine`)** | Copy production artifacts, `chown`, run as `appuser`, `HEALTHCHECK`, `CMD` |

---

## Docker layer caching explanation

Docker caches a layer when the **instruction text** and **input files** (e.g., `COPY` checksums) match a previous build.

**Pattern used:** `COPY package.json package-lock.json` → `RUN npm ci` **before** `COPY src/`. Editing only application code **does not** invalidate the expensive `npm ci` layer if lockfiles are unchanged—CI and local rebuilds stay fast.

---

## Image size optimization

| Technique | Effect |
|-----------|--------|
| **Multi-stage** | Final image omits npm cache and builder-only metadata |
| **`npm ci --omit=dev`** | Drops `devDependencies` (e.g. ESLint) from `node_modules` |
| **Alpine base** | Smaller glibc-free userland (trade-off: musl compatibility) |
| **`.dockerignore`** | Stops `docs/`, `tests/`, `.git/` from bloating context or accidental `COPY` |

Compare sizes with `docker images` before/after tags (`docsync:basic` vs `docsync:optimized`).

---

## Security best practices

- **Non-root `USER`** — limits host impact if the process is compromised.  
- **Minimal packages** — only `wget` added for `HEALTHCHECK` (small, explicit).  
- **No secrets in context** — `.env*` excluded via `.dockerignore`.  
- **`NODE_ENV=production`** — reduces verbose errors and aligns dependency behavior.  
- **`chown` on `/app`** — runtime user owns files it reads.  

---

## Non-root user explanation

The final image creates **`appuser` (UID 1001)** in **`appgroup` (GID 1001)**. `USER appuser` ensures **PID 1** is not root. Kubernetes `securityContext.runAsNonRoot` policies align with this pattern.

**Verify:** `docker run --rm docsync:optimized id` → `uid=1001(appuser)`.

---

## Production dependency strategy

**`npm ci --omit=dev`** installs **exact** versions from `package-lock.json` and skips `devDependencies`. CI still runs `npm ci` (full) for lint/tests on the host runner; the **image** carries only runtime libraries (`express`, `ws`, `uuid`).

---

## HEALTHCHECK explanation

`HEALTHCHECK` runs a command **inside the container** on an interval. Here, **`wget`** performs an HTTP probe to **`http://127.0.0.1:3000/health`**, matching `src/server.js`. Orchestrators can map this to **liveness** semantics; Kubernetes manifests may define separate probes, but the image remains self-describing.

---

## `.dockerignore` purpose

The **build context** is zipped and sent to the daemon. `.dockerignore` excludes paths from that archive so that:

1. **Secrets and `.env`** never enter a layer accidentally.  
2. **Large folders** (`node_modules`, `docs`, `tests`) do not slow every build.  
3. **Unrelated changes** (documentation PRs) do not bust cache if you later broaden `COPY` patterns.

---

## Before vs after optimization comparison

| Aspect | PR7 (`docsync:basic`) | PR8 (`docsync:optimized`) |
|--------|------------------------|----------------------------|
| **Stages** | Single `FROM` | **Multi-stage** (`builder` + final) |
| **Runtime user** | `root` (default) | **`appuser` / `appgroup`** |
| **Health signal** | None in Dockerfile | **`HEALTHCHECK`** on `/health` |
| **Context hygiene** | Narrow ignore list | **`docs/`, `coverage`, `*.md`, editors** excluded |
| **Ownership** | Root-owned files | **`chown -R appuser:appgroup /app`** |

Behavioral contract unchanged: server listens on **port 3000**, **`/health`** returns JSON.

---

## Commands used

From repository root.

### `docker build -t docsync:optimized .`

```bash
docker build -t docsync:optimized .
```

**Expected:** BuildKit steps for `[builder]` and final stage; exit code **0**.

---

### `docker images`

```bash
docker images docsync
```

**Expected:** Row for `docsync:optimized` with size typically **smaller than or comparable to** `docsync:basic` (varies with layer deduplication).

---

### `docker history docsync:optimized`

```bash
docker history docsync:optimized --no-trunc
```

**Expected:** Layers showing `COPY`, `RUN npm ci`, `apk add`, `HEALTHCHECK`, etc.

---

### `docker run --rm -p 3000:3000 docsync:optimized`

```bash
docker run --rm -p 3000:3000 docsync:optimized
```

**Expected:** Log line similar to **“DocSync server running on port 3000”**.

---

### `docker inspect docsync:optimized`

```bash
docker inspect docsync:optimized --format '{{json .Config.Healthcheck}}'
docker inspect docsync:optimized --format '{{.Config.User}}'
```

**Expected:** JSON for `Healthcheck` probe; user string **`appuser`** (or empty if only numeric UID in some engines—this image sets user name via `adduser`).

---

### `curl http://localhost:3000/health`

```bash
curl -sSf http://localhost:3000/health
```

**Expected:** `{"status":"healthy",...}` JSON.

---

### Non-root verification

```bash
docker run --rm docsync:optimized id
docker run --rm docsync:optimized whoami
```

**Expected:** `uid=1001(appuser)` and `appuser`.

---

## Expected outputs (summary)

| Check | Pass criteria |
|-------|----------------|
| Build | Exit code 0 |
| Run | Port 3000 responds |
| Health | HTTP 200 JSON from `/health` |
| User | Non-root UID **1001** |
| Inspect | `Healthcheck` present in image config |

---

## Screenshots and proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | Multi-stage `Dockerfile` | `docs/proofs/4.14-opt-dockerfile.png` |
| 2 | `.dockerignore` | `docs/proofs/4.14-opt-dockerignore.png` |
| 3 | `docker build` success | `docs/proofs/4.14-opt-docker-build.png` |
| 4 | `docker history docsync:optimized` | `docs/proofs/4.14-opt-docker-history.png` |
| 5 | `docker run` logs | `docs/proofs/4.14-opt-docker-run.png` |
| 6 | `curl /health` | `docs/proofs/4.14-opt-health.png` |
| 7 | `docker inspect` (Healthcheck / User) | `docs/proofs/4.14-opt-docker-inspect.png` |
| 8 | `docker run … id` / `whoami` | `docs/proofs/4.14-opt-nonroot.png` |

---

## Validation checklist

- [ ] Read optimized **`Dockerfile`** and traced data flow **builder → final**  
- [ ] Confirmed **`.dockerignore`** excludes `docs`, `tests`, `.git`, `.github`, `coverage`, secrets  
- [ ] **`docker build -t docsync:optimized .`** succeeds  
- [ ] **`docker run`** + **`curl /health`** succeeds  
- [ ] **`docker inspect`** shows **Healthcheck** and non-root **User**  
- [ ] Captured proofs per `docs/proofs/README.md` (optimization checklist)  
- [ ] Opened PR **`spr8-dockerfile-optimization`** for review  

---

## Learning outcome

After **Assignment 4.14 (optimization) / A-08**, you can:

- Justify **multi-stage** vs single-stage for Node services.  
- Apply **cache-friendly** `COPY`/`RUN` ordering and a disciplined **`.dockerignore`**.  
- Configure **`HEALTHCHECK`** and **non-root** execution for safer defaults.  
- Use **`docker history`** and **`docker inspect`** to audit images before promotion.  

---

## References

- [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)  
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)  
- [HEALTHCHECK](https://docs.docker.com/reference/dockerfile/#healthcheck)  
