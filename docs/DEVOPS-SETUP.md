# DevOps local setup — DocSync

This folder holds proof of local tooling and setup notes for the DocSync project (real-time document editing with CI/CD and Kubernetes).

## Operating system

- **OS:** macOS 26.3.1 (Darwin 25.3.0), **arm64** (Apple Silicon)
- **Shell:** zsh
- **IDE:** Cursor / VS Code–compatible editor (use whichever your course accepts as an IDE)

## Problem statement (context)

DocSync addresses **version conflicts and sync failures** that lose user work, and **environment drift** where developers cannot reproduce production behavior. This repo uses **Docker images as immutable artifacts** and **Kubernetes** so local and cloud run the same packaged application, with CI/CD tying every image to a Git commit.

## Tool installation checklist

Use this as your submission checklist. Check each item after you have installed and verified it locally (not via a web-only sandbox).

- [x] **Git** — `git --version`
- [x] **Docker Desktop** — `docker --version` and `docker run hello-world` (daemon must be running)
- [x] **kubectl** — `kubectl version --client`
- [x] **Helm** — `helm version` (installed here via Homebrew: `brew install helm`)
- [ ] **Local Kubernetes cluster** — `kubectl cluster-info` succeeds  
  - **Docker Desktop:** Settings → Kubernetes → enable Kubernetes, wait until green, then re-run `kubectl cluster-info`  
  - **Or** Minikube: `minikube start`  
  - **Or** kind: `kind create cluster`
- [x] **Supporting tools** — `curl`, `bash` or `zsh`, and an IDE

## Screenshots

Place **clear terminal screenshots** in `devops-setup/screenshots/` with these names (or rename consistently and list them in your submission):

| File | Command / content to show |
|------|---------------------------|
| `01-git-version.png` | `git --version` |
| `02-docker-version.png` | `docker version` (client + server) |
| `03-docker-hello-world.png` | `docker run hello-world` through “Hello from Docker!” |
| `04-kubectl-client.png` | `kubectl version --client` |
| `05-helm-version.png` | `helm version` |
| `06-kubectl-cluster-info.png` | `kubectl cluster-info` (must show a running cluster) |

**Note:** Until a local cluster is running, `kubectl cluster-info` will fail (for example, connection refused to the API server). Capture `06-kubectl-cluster-info.png` **after** enabling Docker Desktop Kubernetes or starting Minikube/kind.

## Text log of verification commands

For convenience, terminal output from the verification commands on this machine is saved in:

- `verification-output.txt`

Use it alongside your screenshots; it is not a substitute for images if your rubric requires screenshots.

## Setup notes (issues encountered)

1. **Docker daemon not running** — The first `docker run hello-world` failed with “Cannot connect to the Docker daemon.” Starting **Docker Desktop** (`open -a Docker` on macOS) fixed it once the engine was up.
2. **Helm missing** — `helm` was not on `PATH`; it was installed with Homebrew (`brew install helm`).
3. **No Kubernetes API server** — `kubectl` was installed, but the default context pointed at `localhost:8080` with nothing listening. **Remediation:** enable Kubernetes in Docker Desktop, or run Minikube/kind, then confirm with `kubectl cluster-info`.

## Running the DocSync project (after `npm install`)

From the repository root:

```bash
npm install
npm test
npm start
```

- Service listens on **port 3000** (see `src/server.js`).
- Quick check: `curl http://127.0.0.1:3000/health`

## Related documentation

- Root `README.md` — architecture, CI/CD, and Kubernetes deployment overview.
- `video_script.md` — spoken script for a walkthrough video of setup and the app.
