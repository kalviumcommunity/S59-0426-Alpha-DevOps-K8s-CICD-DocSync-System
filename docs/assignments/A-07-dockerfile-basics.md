# Assignment A-07 / 4.14 — Writing Dockerfiles: Base Images, Layers, Caching, and Best Practices

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr7-dockerfile-basics`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.14** (tracker ID: **A-07**) |
| **Module reference** | **Module 4** — Container build specifications: `Dockerfile` syntax, layer ordering, cache behavior, and production-oriented defaults for DocSync |
| **Objective** | Document what a **`Dockerfile`** is; explain each instruction used in this repository’s DocSync image; justify **base image** choice; relate instructions to **layers** and **build cache**; walk through **`docker build` / `docker run` / health check** with expected outputs and proof artifacts. |

---

## What is a Dockerfile?

A **`Dockerfile`** is a **declarative build recipe**: an ordered list of instructions the Docker engine executes to produce an **OCI image**. Each filesystem-changing step typically creates a **new read-only layer**; runtime metadata (`EXPOSE`, `ENV`, `CMD`) is stored in the image config.

---

## Explanation of each Dockerfile instruction used

| Instruction | Purpose in DocSync image |
|-------------|-------------------------|
| **`FROM node:20-alpine`** | Select upstream OS + Node runtime; `20` matches project and CI; `alpine` reduces size. |
| **`WORKDIR /app`** | Create/set working directory for `RUN`, `COPY`, and the default process CWD. |
| **`COPY package.json package-lock.json ./`** | Add lockfile-backed manifests before source so dependency layer caches when only `src/` changes. |
| **`RUN npm ci --omit=dev`** | Install exact versions from `package-lock.json`; omit `devDependencies` (e.g. ESLint) for smaller production trees. |
| **`COPY src/ ./src/`** | Add application code required at runtime. |
| **`ENV NODE_ENV=production`** | Enables production-oriented behavior in Node libraries. |
| **`ENV PORT=3000`** | Matches server default in `src/server.js`. |
| **`EXPOSE 3000`** | Documents the listening port for operators and orchestrators (does not publish the port by itself). |
| **`CMD ["node", "src/server.js"]`** | Default process PID 1 — starts DocSync HTTP/WebSocket server. |

---

## Base image selection

| Choice | Rationale |
|--------|-----------|
| **`node:20-alpine`** | Aligns with **Node 20** in course tooling and `package.json` engines expectations; **Alpine** yields smaller pull/push times suitable for labs. |
| **Official `node` image** | Maintained by Docker Library; predictable updates. |

Trade-off: **musl** (Alpine) vs **glibc** (Debian-based `node:20-bookworm`) — some native addons differ; DocSync uses pure JS dependencies, so Alpine is appropriate.

---

## Layer creation

Rough mapping (conceptual):

1. **Base layer stack** from `node:20-alpine`  
2. **`WORKDIR`** — metadata / empty layer behavior depending on storage driver  
3. **`COPY package*.json`** — small layer with manifest files  
4. **`RUN npm ci`** — large layer with `node_modules/`  
5. **`COPY src/`** — layer with application source  

Changing **`src/`** alone **does not** invalidate the **`npm ci`** layer if `package-lock.json` is unchanged—this is **layer caching** in action.

---

## Docker build process

1. Docker sends the **build context** (directory, respecting `.dockerignore`) to the daemon.  
2. Each instruction is evaluated; cache hits reuse existing layers.  
3. Final image receives a **config** (`ENV`, `EXPOSE`, `CMD`, etc.).  
4. Result is tagged locally (e.g. `docsync:basic`) and optionally pushed to a registry.

---

## Commands used

Run from the **repository root** (where the `Dockerfile` lives).

### `docker build -t docsync:basic .`

```bash
docker build -t docsync:basic .
```

**Expected output:** step lines `#1 [internal] ...`, `#5 [3/5] RUN npm ci ...`, ending with `naming to docker.io/library/docsync:basic` or `exporting to image` / `writing image sha256:...` (BuildKit). Exit code **0**.

---

### `docker images`

```bash
docker images docsync
```

**Expected output:** row with tag `basic`, image ID, size (tens to low hundreds of MB depending on layers).

---

### `docker run --rm -p 3000:3000 docsync:basic`

```bash
docker run --rm -p 3000:3000 docsync:basic
```

**Expected output:** server logs on stdout (e.g. listening on port 3000). Use another terminal for `curl` below. Stop with `Ctrl+C` (`--rm` removes container on exit).

---

### `curl http://localhost:3000/health`

```bash
curl -sSf http://localhost:3000/health
```

**Expected output:** JSON such as `{"status":"healthy","uptime":...}` — confirms container networking and Express route.

---

## Expected outputs (summary)

| Step | Success signal |
|------|----------------|
| Build | Exit code 0; image listed under `docker images` |
| Run | No crash loop; port 3000 reachable on host |
| Health | HTTP 200 + JSON body from `/health` |

---

## Screenshots and proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `Dockerfile` in editor (major sections visible) | `docs/proofs/4.14-dockerfile.png` |
| 2 | Terminal: successful `docker build` tail | `docs/proofs/4.14-docker-build.png` |
| 3 | `docker images` showing `docsync:basic` | `docs/proofs/4.14-docker-images.png` |
| 4 | `docker run` logs / running container | `docs/proofs/4.14-docker-run.png` |
| 5 | `curl` or browser hitting `/health` | `docs/proofs/4.14-health-endpoint.png` |

---

## Validation checklist

- [ ] Read repository **`Dockerfile`** and matched instructions to layers/cache story  
- [ ] Built image with **`docker build -t docsync:basic .`**  
- [ ] Ran container with **`-p 3000:3000`** and verified **`/health`**  
- [ ] Captured proofs per `docs/proofs/README.md` (Assignment 4.14)  
- [ ] Opened PR **`spr7-dockerfile-basics`** for review  

---

## Learning outcome

After **Assignment 4.14 / A-07**, you can:

- Author a **minimal production Dockerfile** for a Node service with correct **layer order** for caching.  
- Explain **`FROM` → `WORKDIR` → `COPY` → `RUN` → `CMD`** in your own words.  
- Debug common failures (**missing file in context**, **`npm ci` lockfile drift**, **wrong `WORKDIR`**) using build logs.  

---

## References

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)  
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)  
- Repository: `Dockerfile`, `.dockerignore`, `package.json`  
