# Assignment A-09 / 4.15 — Building, Running, and Debugging Containers Locally

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr9-build-run-containers`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.15** (tracker ID: **A-09**) |
| **Module reference** | **Module 4** — Local container workflow: build, run, observe, and validate before shipping images to a registry or Kubernetes |
| **Objective** | Establish a repeatable **local Docker workflow** for DocSync: build a tagged image, run a named container with **port mapping**, validate **`/health`**, and use **lifecycle commands** for stop/remove—mirroring how you gate quality before cluster deployment. |

---

## Purpose of building and running containers locally

| Goal | Why it matters |
|------|----------------|
| **Parity** | Same `Dockerfile` that CI builds should run on your laptop |
| **Fast feedback** | Catch missing files, bad `CMD`, or wrong `PORT` before push |
| **Safe iteration** | Containers are disposable; reset with `rm` and rebuild |
| **Evidence** | Screenshots/logs satisfy coursework and PR review |

---

## Local Docker workflow

```text
  Edit code / Dockerfile
          │
          ▼
   docker build -t docsync:local .
          │
          ▼
   docker run --name docsync-local -p 3000:3000 docsync:local
          │
          ▼
   curl /health  ·  docker logs  ·  docker exec
          │
          ▼
   docker stop docsync-local && docker rm docsync-local
```

**Automation:** [`scripts/docker-local-run.sh`](../../scripts/docker-local-run.sh) performs **build → remove old container → run detached** with status messages (safe to re-run).

---

## Build command explanation

```bash
docker build -t docsync:local .
```

| Flag / token | Meaning |
|--------------|---------|
| **`docker build`** | Execute `Dockerfile` instructions; emit an image |
| **`-t docsync:local`** | Repository `docsync`, tag `local` (mutable lab tag) |
| **`.`** | Build context = current directory (respects `.dockerignore`) |

**Outcome:** Image ID recorded locally; subsequent builds may reuse cached layers.

---

## Run command explanation

```bash
docker run --name docsync-local -p 3000:3000 docsync:local
```

| Flag | Meaning |
|------|---------|
| **`--name docsync-local`** | Stable name for `stop`/`logs`/`rm` |
| **`-p 3000:3000`** | Publish container port **3000** on host **3000** |
| **`docsync:local`** | Image to instantiate |

**Foreground vs detached:** Foreground attaches stdout (good for demos). For background work use **`-d`** (the helper script uses `-d` so your shell returns).

---

## Port mapping explanation

**`-p <host>:<container>`** binds a host port to a container port. DocSync listens on **`PORT` (default 3000)** inside the container. Mapping **`3000:3000`** makes `http://localhost:3000` reach the app. If host 3000 is busy, use **`-p 3001:3000`** and curl `localhost:3001`.

---

## Container lifecycle commands

| Intent | Command |
|--------|---------|
| **List running** | `docker ps` |
| **List all** | `docker ps -a` |
| **Logs** | `docker logs docsync-local` (add `-f` to follow) |
| **Stop** | `docker stop docsync-local` |
| **Remove** | `docker rm docsync-local` |
| **Force remove** | `docker rm -f docsync-local` |
| **Shell inside** | `docker exec -it docsync-local /bin/sh` |

---

## Health endpoint validation

DocSync exposes **`GET /health`** returning JSON (`status`, `uptime`). From the host:

```bash
curl -sSf http://localhost:3000/health
```

**`-sSf`:** silent, show errors, fail on HTTP error—ideal for scripts and CI smoke tests.

---

## How this validates the DocSync app before Kubernetes deployment

| Local check | Kubernetes analogue |
|-------------|---------------------|
| Image builds cleanly | CI `docker/build-push-action` succeeds |
| `/health` OK on mapped port | **Readiness** / **liveness** probes hit same path |
| Logs show listen message | Pod logs in `kubectl logs` |
| Process runs as non-root (PR8 image) | `securityContext` compliance |

Local validation **reduces** “first failure in cluster” surprises: networking, entrypoint, and dependencies are proven before `kubectl apply`.

---

## Commands used

### `docker build -t docsync:local .`

**Expected:** BuildKit steps complete; `exporting to image` / `naming to … docsync:local`; exit code **0**.

---

### `docker images`

```bash
docker images docsync
```

**Expected:** Row with tag **`local`**, image ID, size.

---

### `docker run --name docsync-local -p 3000:3000 docsync:local`

**Expected (foreground):** Server log line (e.g. listening on 3000); terminal occupied until **Ctrl+C** (stops container unless `-d`).

**Detached alternative:** `docker run -d --name docsync-local -p 3000:3000 docsync:local` then use `docker logs`.

---

### `docker ps`

```bash
docker ps --filter name=docsync-local
```

**Expected:** One row; **PORTS** shows `0.0.0.0:3000->3000/tcp`.

---

### `curl http://localhost:3000/health`

**Expected:** JSON body `{"status":"healthy",…}`.

---

### `docker stop docsync-local` / `docker rm docsync-local`

```bash
docker stop docsync-local
docker rm docsync-local
```

**Expected:** Container stops; `docker ps -a` no longer lists it (after `rm`).

---

### Helper script

```bash
chmod +x scripts/docker-local-run.sh
./scripts/docker-local-run.sh
```

**Expected:** Status banners, successful build, detached run, `docker ps` snippet, printed `curl`/`logs`/`stop` hints.

---

## Expected outputs (summary)

| Step | Pass criteria |
|------|----------------|
| Build | Exit code 0; `docsync:local` exists |
| Run | Container up; port mapped |
| Health | HTTP 200 JSON |
| Stop/Rm | No container name collision on next run |

---

## Screenshots and proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `docker build -t docsync:local .` | `docs/proofs/4.15-docker-build.png` |
| 2 | `docker images` | `docs/proofs/4.15-docker-images.png` |
| 3 | `docker run` (command + output) | `docs/proofs/4.15-docker-run.png` |
| 4 | `docker ps` | `docs/proofs/4.15-docker-ps.png` |
| 5 | `curl /health` | `docs/proofs/4.15-curl-health.png` |
| 6 | `./scripts/docker-local-run.sh` | `docs/proofs/4.15-script-run.png` |

---

## Validation checklist

- [ ] Built **`docsync:local`** from repo root  
- [ ] Ran **`docsync-local`** with **`-p 3000:3000`**  
- [ ] **`curl /health`** succeeded  
- [ ] Stopped and removed container without orphan name conflicts  
- [ ] Ran **`scripts/docker-local-run.sh`** successfully (optional but recommended)  
- [ ] Attached proofs per `docs/proofs/README.md` (Assignment 4.15)  
- [ ] Opened PR **`spr9-build-run-containers`** for review  

---

## Learning outcome

After **Assignment 4.15 / A-09**, you can:

- Execute a **full local loop** build → run → validate → teardown for DocSync.  
- Interpret **port publishing** and common **`docker ps` / `logs`** outputs.  
- Explain how local checks de-risk the **Kubernetes rollout** path.  

---

## References

- [Docker CLI](https://docs.docker.com/reference/cli/docker/)  
- Repository: `Dockerfile` (PR8 optimized), `scripts/docker-local-run.sh`  
