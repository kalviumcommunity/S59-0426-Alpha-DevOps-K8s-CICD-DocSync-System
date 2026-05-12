# Assignment A-10 / 4.15 (debugging) — Debugging Containers Locally with Docker

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr10-container-debugging`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.15 (debugging track)** (tracker ID: **A-10**) |
| **Module reference** | **Module 4** — Operational troubleshooting: logs, inspection, exec, and systematic elimination of runtime faults **before** cluster deployment |
| **Objective** | Use **`docker logs`**, **`docker inspect`**, **`docker exec`**, and **`docker ps` / `docker ps -a`** to diagnose common DocSync container failures; interpret **port mapping** and **health** signals; run the read-only helper **`scripts/docker-debug-check.sh`** for repeatable evidence. |

---

## Why container debugging is important

| Reason | Explanation |
|--------|-------------|
| **Fast MTTR** | Most failures are configuration, ports, or crash loops—CLI tools surface them in minutes |
| **Reproducible evidence** | Logs and inspect JSON attach cleanly to PRs and incident tickets |
| **Safer Kubernetes rollouts** | Issues found locally rarely become mysterious `CrashLoopBackOff` mysteries |
| **Shared vocabulary** | Same patterns map to `kubectl logs`, `kubectl describe`, `kubectl exec` |

---

## Common container failure scenarios

| Symptom | Likely causes |
|---------|----------------|
| **`Bind … port is already allocated`** | Another process/container on host port |
| **`Cannot connect to Docker daemon`** | Docker Desktop/daemon stopped |
| **Exit code 137** | OOM killed — tune memory limits |
| **Immediate exit / `Exited (1)`** | App throws on boot — read **`docker logs`** |
| **`curl` hangs** | Wrong **`-p`**, firewall, or app not listening on `PORT` |
| **Health `unhealthy`** | Slow start; wrong path; app only binds `127.0.0.1` incorrectly |

---

## Debugging workflow

1. **Confirm object exists:** `docker ps -a --filter name=docsync-local`  
2. **Classify state:** running vs exited (`docker inspect … .State.Status`)  
3. **Read logs:** `docker logs --tail 200 docsync-local` (add `--timestamps`)  
4. **Validate config:** `docker inspect docsync-local` (ports, env, cmd, health)  
5. **Reproduce inside:** `docker exec -it docsync-local sh` then `wget`/`curl` loopback  
6. **Validate host path:** `curl http://localhost:3000/health` (match **`-p`**)

---

## Using `docker logs`

```bash
docker logs docsync-local
docker logs --tail 100 --timestamps docsync-local
docker logs -f docsync-local
```

| Flag | Use |
|------|-----|
| **`--tail`** | Limit noise on chatty services |
| **`--timestamps`** | Correlate with host clock |
| **`-f`** | Follow (Ctrl+C stops follow, not container unless `-f` on stopped?) |

**Expected:** stack traces, listen banner, or npm/node errors explaining exit.

---

## Using `docker inspect`

```bash
docker inspect docsync-local
docker inspect docsync-local --format '{{json .State}}'
docker inspect docsync-local --format '{{json .NetworkSettings.Ports}}'
```

**Expected:** JSON with **`State`**, **`Config`**, **`NetworkSettings`**, **`Health`** (when defined). Use `--format` to reduce noise.

---

## Using `docker exec`

```bash
docker exec docsync-local id
docker exec -it docsync-local sh
```

**Interactive shell:** `sh` on Alpine is typical. **Non-interactive:** quick probes (`id`, `wget`, `ls`).

**Expected:** Shell inside **running** container; fails if container stopped.

---

## Checking running containers: `docker ps`

```bash
docker ps
docker ps --filter name=docsync-local
```

**Expected:** `STATUS` **Up** …, **PORTS** `0.0.0.0:3000->3000/tcp` when published.

---

## Checking stopped containers: `docker ps -a`

```bash
docker ps -a
```

**Expected:** exited rows with **Exit code**; helps find **orphaned** names blocking `docker run --name`.

---

## Debugging port mapping issues

| Check | Command / action |
|-------|------------------|
| **Published ports** | `docker inspect … '{{json .NetworkSettings.Ports}}'` |
| **Host listen** | `lsof -i :3000` (macOS) / `ss -lntp` (Linux) |
| **Try alternate host port** | `docker run … -p 3001:3000 …` then `curl localhost:3001/health` |

---

## Debugging failed health checks

DocSync image defines **`HEALTHCHECK`** against `/health`. Inspect:

```bash
docker inspect docsync-local --format '{{json .State.Health}}'
```

**Failing streak** with **503** or connection refused in logs → app not ready or wrong internal URL. Increase **`start-period`** only in Dockerfile (out of scope for this PR’s script-only work).

---

## Debugging image/container mismatch

| Symptom | Fix |
|---------|-----|
| **Old behavior after rebuild** | Run **new** container from new tag; remove stale name |
| **Wrong image id** | `docker inspect docsync-local --format '{{.Image}}'` vs `docker images` |

---

## How debugging supports reliable deployment before Kubernetes

| Docker practice | Kubernetes analogue |
|-----------------|---------------------|
| `docker logs` | `kubectl logs` |
| `docker inspect` | `kubectl describe pod` |
| `docker exec` | `kubectl exec` |
| Health state | **Liveness/Readiness** probes |

Fixing issues **locally** reduces failed rollouts and noisy rollbacks.

---

## Commands used

### `docker ps` / `docker ps -a`

**Expected:** table of containers; filters narrow rows.

---

### `docker logs docsync-local`

**Expected:** application stdout/stderr.

---

### `docker inspect docsync-local`

**Expected:** large JSON; use `--format` for fields.

---

### `docker exec -it docsync-local sh`

**Expected:** interactive shell; type `exit` to leave (container keeps running).

---

### `curl http://localhost:3000/health`

**Expected:** JSON `{"status":"healthy",…}`.

---

### `docker stop docsync-local` / `docker rm docsync-local`

**Expected:** clean teardown when you are **done** debugging (not used by the read-only debug script).

---

### Read-only bundle

```bash
chmod +x scripts/docker-debug-check.sh
./scripts/docker-debug-check.sh
```

**Expected:** status banners, `ps`/`inspect`/`logs` excerpts, optional `curl`/`exec` probes — **no container mutation**.

---

## Expected outputs (summary)

| Step | Pass criteria |
|------|----------------|
| `docker ps` | Shows expected **PORTS** when running |
| `docker logs` | Explains crashes or confirms listen |
| `inspect` | **Running=true** or meaningful **ExitCode** |
| `exec` | Works only when **running** |
| `curl` | HTTP 200 from mapped host port |

---

## Screenshots and proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `docker ps` / filtered | `docs/proofs/4.15-dbg-docker-ps.png` |
| 2 | `docker logs` | `docs/proofs/4.15-dbg-docker-logs.png` |
| 3 | `docker inspect` (formatted) | `docs/proofs/4.15-dbg-docker-inspect.png` |
| 4 | `docker exec -it … sh` session | `docs/proofs/4.15-dbg-docker-exec.png` |
| 5 | Health / `curl` / inspect health JSON | `docs/proofs/4.15-dbg-health.png` |
| 6 | `./scripts/docker-debug-check.sh` | `docs/proofs/4.15-dbg-script.png` |

---

## Validation checklist

- [ ] Reproduced a **running** `docsync-local` (e.g. via `scripts/docker-local-run.sh`)  
- [ ] Collected **`docker logs`** for a controlled failure and a healthy run  
- [ ] Used **`docker inspect`** to view **State** and **Ports**  
- [ ] Used **`docker exec`** (non-destructive command) inside the container  
- [ ] Ran **`scripts/docker-debug-check.sh`** multiple times without side effects  
- [ ] Captured proofs per `docs/proofs/README.md` (debugging checklist)  
- [ ] Opened PR **`spr10-container-debugging`** for review  

---

## Learning outcome

After **Assignment 4.15 (debugging) / A-10**, you can:

- Follow a **structured** debug path from **symptom → logs → inspect → exec**.  
- Separate **host networking** issues from **in-container** failures.  
- Map Docker debugging skills to **Kubernetes** operational commands.  

---

## References

- [docker logs](https://docs.docker.com/reference/cli/docker/container/logs/)  
- [docker inspect](https://docs.docker.com/reference/cli/docker/inspect/)  
- [docker exec](https://docs.docker.com/reference/cli/docker/container/exec/)  
- Helper scripts: `scripts/docker-local-run.sh`, `scripts/docker-debug-check.sh`  
