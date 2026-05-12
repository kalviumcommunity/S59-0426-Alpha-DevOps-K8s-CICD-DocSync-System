# Assignment A-05 / 4.12 — Introduction to Containers and Containerization Concepts

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr5-containerization-concepts`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.12** (tracker ID: **A-05**) |
| **Module reference** | **Module 4** — Container fundamentals: packaging, isolation, and portability as the basis for CI/CD and Kubernetes |
| **Objective** | Explain **what containerization is** and why it dominates modern DevOps; contrast containers with **virtual machines**; describe the **container lifecycle** and **Docker’s role**; map DocSync’s path from **source → image → running container**; practice essential **Docker CLI** commands with clear expected outputs. |

---

## What is containerization?

**Containerization** is the practice of packaging an application together with its **runtime dependencies** (libraries, configs, binaries) into a **filesystem bundle** that runs on a **shared host kernel** inside isolated namespaces and cgroups. The runnable artifact is typically an **OCI image**; a running instance is a **container**.

| Term | Meaning |
|------|---------|
| **Image** | Immutable template (layers + metadata + default command) |
| **Container** | Writable thin layer on top of an image + isolated process tree |
| **Registry** | Store for images (e.g., GHCR) pulled at deploy time |

---

## Why containers are used in DevOps

| Driver | Explanation |
|--------|----------------|
| **Parity** | Same artifact in dev, CI, staging, and prod reduces “works on my machine” |
| **Speed** | Start/stop in seconds vs minutes for full VMs |
| **Density** | Many containers per host with defined CPU/memory limits |
| **Immutability** | Promote **digest-addressed** images instead of mutating servers |
| **Automation** | `docker build` / `build-push-action` integrate cleanly into pipelines |

---

## Containers vs virtual machines

| Dimension | Virtual machine (VM) | Container |
|-----------|----------------------|-----------|
| **Isolation** | Full guest OS + hypervisor | Namespaces + cgroups on host kernel |
| **Boot time** | Minutes | Seconds |
| **Image size** | Large (OS + apps) | Smaller (app + userland layers) |
| **Kernel** | Each VM has its own kernel | Containers share the **host** kernel |
| **Use case** | Strong isolation, mixed OS | Cloud-native microservices, batch jobs |

Containers **do not replace** VMs; they often **run inside** VMs or on cloud-managed Kubernetes nodes.

---

## Benefits of containers

- **Portable packaging** — “build once, run anywhere” with a compatible kernel/runtime  
- **Versioned releases** — tags and digests map to Git commits  
- **Composable pipelines** — lint/test, then build image as a gate  
- **Resource controls** — CPU/memory limits align with Kubernetes requests/limits  
- **Security posture** — smaller surface, non-root users, read-only rootfs (patterns applied in hardened Dockerfiles)  

---

## Container lifecycle

High-level stages from image to exit:

```text
  ┌─────────┐     ┌─────────┐     ┌──────────┐     ┌──────────┐     ┌─────────┐
  │  Build  │────▶│  Store  │────▶│   Pull   │────▶│   Run    │────▶│  Stop   │
  │ (image) │     │(registry│     │ (docker  │     │(container│     │/ remove │
  │         │     │ / cache)│     │  pull)  │     │  start)  │     │         │
  └─────────┘     └─────────┘     └──────────┘     └──────────┘     └─────────┘
                                                        │
                                                        ▼
                                                 ┌──────────────┐
                                                 │ Exec / logs │
                                                 │ healthcheck  │
                                                 └──────────────┘
```

| Phase | Typical Docker CLI |
|-------|-------------------|
| Create image | `docker build` |
| Distribute | `docker push` / CI registry upload |
| Obtain locally | `docker pull` (implicit on `run` if missing) |
| Run | `docker run` |
| Observe | `docker ps`, `docker logs` |
| Stop / remove | `docker stop`, `docker rm` |

---

## Role of Docker in containerization

**Docker** (the product) popularized the developer workflow: `Dockerfile` → **image** → **container**, plus **Docker Hub** and tooling that became the de facto standard before **OCI** formalized image and runtime specs. Today, **Docker Engine / Docker Desktop**, **BuildKit**, and **docker buildx** remain common for local builds; Kubernetes often uses **containerd** under the hood while still consuming **OCI images** built with Docker-compatible tools.

---

## How this project uses containers

DocSync ships as a **Node.js** service packaged in the repository’s **`Dockerfile`** (multi-stage build, production-oriented runtime). CI builds and pushes an image to **GHCR**; Kubernetes manifests reference a container image for the `Deployment`. This repository treats the **image as the unit of deployment**, not raw source on the server.

| Artifact | Role |
|----------|------|
| `Dockerfile` | Declarative build steps for the DocSync image |
| `.dockerignore` | Reduces build context size and accidental secret inclusion |
| GitHub Actions workflow | Automates image build and registry push on `main` |

> This assignment documents concepts only; it does **not** change the `Dockerfile` or workflows.

---

## Source → Image → Container flow

```text
  Git repository (source)
           │
           ▼
    docker build (Dockerfile + context)
           │
           ▼
      OCI image (layers + metadata)
           │
           ├──► Registry (GHCR)     …… CI/CD
           │
           ▼
    docker run / Kubernetes Pod
           │
           ▼
    Running container (isolated process + writable layer)
```

**Narrative:** Developers commit to Git; **build** seals dependencies into an image; the image is **stored** in a registry; **runtime** pulls and starts a **container** with the configured command and environment.

---

## Real-world use case

| Scenario | How containers help |
|----------|----------------------|
| **SaaS API rollout** | Rolling update swaps Pod images with health checks |
| **Batch / ETL** | Same image runs on schedule in Kubernetes Jobs |
| **Local dev** | `docker run` matches production Node/OS libraries |
| **Compliance** | Signed images + SBOM attach to digest for audit |

---

## Commands and examples

Replace image names and tags with your own when following along.

### `docker --version`

```bash
docker --version
```

**Expected output:** one line such as `Docker version 27.x.x, build ...` (exact numbers vary by channel).

---

### `docker images`

```bash
docker images
```

**Expected output:** table columns `REPOSITORY`, `TAG`, `IMAGE ID`, `CREATED`, `SIZE`; may be empty on a fresh engine.

---

### `docker ps`

```bash
docker ps
docker ps -a
```

**Expected output:** `docker ps` lists **running** containers; `docker ps -a` includes **stopped** containers.

---

### `docker build`

```bash
cd S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System
docker build -t docsync:4.12-lab .
```

**Expected output:** step-by-step `#N [internal]` / `RUN` / `COPY` lines, ending with `Successfully tagged docsync:4.12-lab` (or digest reference with BuildKit).

---

### `docker run`

```bash
docker run --rm -p 3000:3000 docsync:4.12-lab
```

**Expected output:** application logs to stdout; from another terminal, `curl -sSf http://localhost:3000/health` may return OK if the service exposes `/health` (stop with `Ctrl+C` or `--rm` exits when process ends).

**Detached example:**

```bash
docker run -d --name docsync-lab -p 3000:3000 docsync:4.12-lab
docker ps
docker stop docsync-lab
```

---

## Expected outputs (summary)

| Command | Success signal |
|---------|----------------|
| `docker --version` | Version string printed |
| `docker images` | Tabular listing, no daemon error |
| `docker ps` / `docker ps -a` | Headers + rows (possibly empty) |
| `docker build` | Exit code 0; image visible in `docker images` |
| `docker run` | Container starts; port map works; clean stop |

---

## Screenshots and proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `docker --version` | `docs/proofs/4.12-docker-version.png` |
| 2 | `docker images` (include DocSync image if built) | `docs/proofs/4.12-docker-images.png` |
| 3 | `docker ps` or `docker ps -a` | `docs/proofs/4.12-docker-ps.png` |
| 4 | Lifecycle diagram (this doc section or whiteboard export) | `docs/proofs/4.12-lifecycle.png` |
| 5 | Project docs: `README.md` or this assignment in browser/IDE showing containerization narrative | `docs/proofs/4.12-project-docs.png` |

---

## Validation checklist

- [ ] Can define **image** vs **container** in one sentence each  
- [ ] Can name **two** differences between VMs and containers  
- [ ] Can walk through **Source → Image → Container** for DocSync  
- [ ] Ran **`docker build`** and **`docker run`** successfully (or captured CI build logs as alternative evidence per instructor)  
- [ ] Attached proofs per `docs/proofs/README.md` (Assignment 4.12)  
- [ ] Opened PR **`spr5-containerization-concepts`** for review  

---

## Learning outcome

After **Assignment 4.12 / A-05**, you can:

- Justify **why** containers are the default packaging model for DocSync-style services.  
- Trace the **lifecycle** from Dockerfile through registry to runtime.  
- Use core **`docker`** commands to **inspect** and **run** images safely.  
- Relate local containers to **Kubernetes** “Pod = one or more containers” mental model for upcoming work.  

---

## References

- [OCI](https://opencontainers.org/)  
- [Docker documentation](https://docs.docker.com/)  
- Repository: `README.md`, `Dockerfile` (read-only study for this assignment)  
