# Assignment A-06 / 4.13 — Docker Architecture: Images, Containers, and Layers

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr6-docker-architecture`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.13** (tracker ID: **A-06**) |
| **Module reference** | **Module 4** — Docker engine architecture: client/daemon split, image layering, registries, and how DocSync ships as an OCI artifact |
| **Objective** | Explain **Docker’s components** (client, daemon, images, containers, layers, registry), contrast **image vs container**, describe **layer caching**, map the **source → Dockerfile → image → container → registry** path for DocSync, and practice inspection commands with documented expected outputs. |

---

## Docker architecture overview

Docker follows a **client–server** model:

```text
  ┌─────────────────┐         REST / UNIX socket         ┌──────────────────┐
  │  Docker CLI     │ ──────────────────────────────────▶ │  Docker daemon   │
  │  (client)       │ ◀────────────────────────────────── │  (dockerd)       │
  └─────────────────┘         JSON / stream responses      └────────┬─────────┘
                                                                     │
                    ┌───────────────────────────────────────────────┼────────────────────────┐
                    ▼                                               ▼                        ▼
             ┌─────────────┐                                 ┌──────────────┐          ┌─────────────┐
             │   Images    │                                 │  Containers  │          │  Networks   │
             │  (layers)   │                                 │  (runtime)   │          │  / volumes   │
             └─────────────┘                                 └──────────────┘          └─────────────┘
```

The **daemon** implements build, pull, run, and networking; the **client** is what you type in the terminal (`docker …`).

---

## Docker client

- **Role:** User-facing binary (`docker`) that parses commands and talks to the daemon.  
- **Location:** Installed with Docker Desktop / Docker Engine package.  
- **Config:** `~/.docker/config.json` (registry logins, CLI preferences).  
- **API version:** `docker version` shows **Client** and **Server** API versions—both must be compatible.

---

## Docker daemon

- **Role:** Long-running **`dockerd`** process: manages images, containers, storage drivers, networks, and security options.  
- **Socket:** On Linux often `/var/run/docker.sock` (root-equivalent access—protect it).  
- **Context:** Docker **contexts** let the CLI point at remote daemons (e.g., cloud builders) without reinstalling.

---

## Docker images

- **Definition:** Ordered stack of **read-only layers** plus configuration (env defaults, `CMD`, `ENTRYPOINT`, exposed ports, labels).  
- **Identity:** **Image ID** (digest over config + layer chain); human-friendly **repo:tag** (mutable).  
- **Storage:** Content-addressable storage driver (e.g., overlay2) deduplicates identical layers across images.

---

## Docker containers

- **Definition:** A **runnable instance** of an image: writable **container layer** + isolated namespaces (PID, network, mount, etc.).  
- **Lifecycle:** `create` → `start` → `running` → `stopped` → `removed`.  
- **Ephemeral by default:** Data written only to the container layer is lost unless bound to **volumes** or **bind mounts**.

---

## Docker layers

- Each Dockerfile instruction that mutates the filesystem typically creates a **new layer**.  
- **Union mount** presents a single merged filesystem view to the container.  
- **Sharing:** Identical layers across images are stored once on disk.

---

## Docker registry

- **Role:** Remote store for images (Docker Hub, **GHCR**, ECR, etc.).  
- **Operations:** `docker push`, `docker pull`; Kubernetes **image** fields reference `registry/repo:tag@sha256:…`.  
- **Authentication:** `docker login` stores credentials (often in `~/.docker/config.json`).

---

## Image vs container

| Aspect | Image | Container |
|--------|--------|-----------|
| **Mutability** | Immutable template (tags can move; digests are stable) | Writable thin layer on top |
| **Count** | Few reused images | Many instances possible |
| **Analogy** | Class | Object instance |
| **CLI** | `docker images`, `docker history` | `docker ps`, `docker inspect` (by container ID) |

---

## Layer caching concept

During **`docker build`**, Docker reuses a **cached layer** if:

1. The **instruction** is unchanged, and  
2. **Inputs** referenced by that instruction are unchanged (e.g., same `COPY` source checksum for those files).

**Implications**

- Order instructions from **least** to **most** frequently changing (e.g., `COPY package*.json` + `npm ci` **before** `COPY src`) to maximize cache hits—DocSync’s multi-stage `Dockerfile` follows this pattern conceptually.  
- **`--no-cache`** forces a full rebuild when debugging flaky layers.

---

## How Docker architecture applies to this project

| Component | DocSync usage |
|-----------|----------------|
| **Client** | Developers and CI runners invoke `docker build` / `build-push-action` |
| **Daemon** | Builds image layers; runs local containers for smoke tests |
| **Images** | Produced from repository `Dockerfile`; tagged in CI metadata |
| **Registry** | **GHCR** stores images consumed by Kubernetes manifests |
| **Layers** | Dependency install separated from app copy for cache efficiency |

> This assignment is **documentation only**; it does not modify the `Dockerfile`, manifests, or workflows.

---

## Source code → Dockerfile → Image → Container → Registry flow

```text
  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
  │ Source code │───▶│ Dockerfile  │───▶│    Image    │───▶│  Container  │───▶│  Registry   │
  │  (Git tree) │    │ (build spec)│    │   (layers)  │    │  (runtime)  │    │   (GHCR)    │
  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
        │                    │                  │                 │                  │
        │                    │                  │                 │                  │
   src/, package.json    Instructions      Immutable artifact   Local/CI test    Share with K8s
```

1. **Source:** Application and build context in Git.  
2. **Dockerfile:** Declares base image, dependencies, copy steps, user, health check, `CMD`.  
3. **Image:** Built layers + metadata.  
4. **Container:** `docker run` (or Kubernetes Pod) executes the image’s entrypoint.  
5. **Registry:** Published image for cluster pulls and audit trail.

---

## Commands used

Examples use a **local tag** after you have built an image (e.g. `docsync:4.13-lab`). Replace `<image-name>` and `<container-id>` with real values from your machine.

### `docker version`

```bash
docker version
```

**Expected output:** two sections—**Client** (OS/arch, version) and **Server** (Engine version, API). If the daemon is down, the client prints but **Server** errors.

---

### `docker info`

```bash
docker info
```

**Expected output:** long report: storage driver, root dir, insecure registries, cgroup driver, live/restore, Swarm/Kubernetes plugin hints (varies by install). Confirms daemon health and capacity.

---

### `docker images`

```bash
docker images
docker images --digests
```

**Expected output:** table of `REPOSITORY`, `TAG`, `IMAGE ID`, `CREATED`, `SIZE`; `--digests` adds digest column when available.

---

### `docker ps`

```bash
docker ps
docker ps -a --no-trunc
```

**Expected output:** running containers (`docker ps`); all containers with full command (`-a --no-trunc`).

---

### `docker history <image-name>`

```bash
docker history docsync:4.13-lab
```

**Expected output:** one row per layer/instruction with `CREATED BY` showing Dockerfile steps (truncated unless `--no-trunc`). Size column shows layer contribution.

---

### `docker inspect <container-id>`

```bash
docker run -d --name docsync-arch-lab -p 3000:3000 docsync:4.13-lab
docker ps -q -f name=docsync-arch-lab
docker inspect "$(docker ps -q -f name=docsync-arch-lab)" | head -n 40
docker stop docsync-arch-lab && docker rm docsync-arch-lab
```

**Expected output:** JSON array with one object: `Id`, `Path`, `Args`, `State`, `Config` (Env, Cmd, Image), `NetworkSettings`, `Mounts`, etc. Use `docker inspect --format '{{.State.Status}}' <id>` for short fields.

---

## Expected outputs (summary)

| Command | Success signal |
|---------|----------------|
| `docker version` | Client + Server (or clear daemon error) |
| `docker info` | Many key/value lines; exit code 0 |
| `docker images` | Tabular listing |
| `docker ps` | Headers; optional rows |
| `docker history` | Layer list tied to build steps |
| `docker inspect` | Valid JSON describing container |

---

## Screenshots and proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `docker version` | `docs/proofs/4.13-docker-version.png` |
| 2 | `docker info` (top section acceptable) | `docs/proofs/4.13-docker-info.png` |
| 3 | `docker images` | `docs/proofs/4.13-docker-images.png` |
| 4 | `docker ps` or `docker ps -a` | `docs/proofs/4.13-docker-ps.png` |
| 5 | `docker history <image>` | `docs/proofs/4.13-docker-history.png` |
| 6 | `docker inspect <container-id>` (JSON or formatted) | `docs/proofs/4.13-docker-inspect.png` |

---

## Validation checklist

- [ ] Can draw **client → daemon** and name one responsibility of each  
- [ ] Can explain **image vs container** with the class/object analogy  
- [ ] Can describe **why layers help** with build speed and storage  
- [ ] Ran **`docker history`** on a DocSync-built image (or instructor-provided image)  
- [ ] Ran **`docker inspect`** on a running or stopped container  
- [ ] Captured proofs listed in `docs/proofs/README.md` (Assignment 4.13)  
- [ ] Opened PR **`spr6-docker-architecture`** for review  

---

## Learning outcome

After **Assignment 4.13 / A-06**, you can:

- Navigate Docker’s **architecture** when debugging “CLI works but build fails” issues.  
- Use **`history`** and **`inspect`** to connect Dockerfile instructions to runtime state.  
- Explain how **registry-backed images** connect Docker workflows to **Kubernetes** in DocSync.  

---

## References

- [Docker architecture overview](https://docs.docker.com/get-started/overview/)  
- [Image layers](https://docs.docker.com/build/cache/)  
- Repository: `Dockerfile`, `README.md` (read-only for this assignment)  
