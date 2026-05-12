# Assignment A-01 / 4.8 — DevOps Workstation Setup

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr1-devops-workstation`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.8** (tracker ID: **A-01**) |
| **Module reference** | **Module 4** — Local development environment & toolchain foundations for container and Kubernetes workflows |
| **Objective** | Install and verify a consistent **DevOps workstation** with **Git**, **Docker**, **kubectl**, **Helm**, **Node.js**, and **npm**, so all subsequent sprint work (images, manifests, CI/CD) can be reproduced on this machine. |

---

## DevOps workstation overview

A DevOps workstation is the **local control plane** for the software delivery loop: version control (Git), immutable packaging (Docker), cluster interaction (`kubectl` / Helm), and application runtime tooling (Node.js / npm) for the DocSync service. Aligning versions with the repository (`Dockerfile` uses Node 20; CI uses `ubuntu-latest`) reduces “works on my machine” drift before changes reach GitHub Actions or Kubernetes.

**Principles for this sprint**

- Prefer **LTS or current stable** releases documented by each vendor.
- Confirm tools are on your **`PATH`** and callable from a non-elevated terminal where possible.
- Capture **proof artifacts** (screenshots or redacted terminal output) under `docs/proofs/` per `docs/proofs/README.md`.

---

## Installation and setup

> Paths and package managers differ by OS. Below: **macOS** (Homebrew), **Linux** (apt-style), and **Windows** pointers. Adjust for your distribution or corporate mirror policy.

### Git

| Platform | Recommended approach | Notes |
|----------|---------------------|--------|
| macOS | `brew install git` or [Xcode Command Line Tools](https://developer.apple.com/xcode/resources/) | `xcode-select --install` installs Apple Git if Brew is unavailable |
| Linux | `sudo apt update && sudo apt install -y git` (Debian/Ubuntu) | RHEL/Fedora: `sudo dnf install git` |
| Windows | [Git for Windows](https://git-scm.com/download/win) | Includes Git Bash; enable “Git from the command line” |

**Baseline configuration (all platforms)**

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

---

### Docker

| Platform | Recommended approach | Notes |
|----------|---------------------|--------|
| macOS / Windows | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Enable **Linux containers** (default); allocate sufficient CPU/RAM |
| Linux | [Docker Engine](https://docs.docker.com/engine/install/) + [post-install](https://docs.docker.com/engine/install/linux-postinstall/) | Add user to `docker` group to avoid `sudo` for every command |

**After install**

```bash
docker version
docker info
```

---

### kubectl

Install a **kubectl** version that matches your target cluster within the [skew policy](https://kubernetes.io/releases/version-skew-policy/) (typically ±1 minor version).

| Platform | Approach |
|----------|----------|
| macOS | `brew install kubectl` |
| Linux | Follow [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) (curl/binary or package manager) |
| Windows | `choco install kubernetes-cli` or download from Kubernetes docs |

**Optional:** `kubectx` / `kubens` for context and namespace switching.

---

### Helm

| Platform | Approach |
|----------|----------|
| macOS | `brew install helm` |
| Linux / Windows | [Installing Helm](https://helm.sh/docs/intro/install/) |

Helm packages Kubernetes manifests into **charts** and supports values-driven releases (planned in later sprint tasks).

---

### Node.js and npm

DocSync targets **Node.js 20** (see repository `Dockerfile` and CI workflow).

| Platform | Approach |
|----------|----------|
| Any | [nodejs.org](https://nodejs.org/) LTS **20.x** installer |
| macOS / Linux | `nvm install 20 && nvm use 20` ([nvm](https://github.com/nvm-sh/nvm)) |
| Windows | [nvm-windows](https://github.com/coreybutler/nvm-windows) or official MSI |

`npm` ships with Node.js. Prefer **`npm ci`** in automation; use **`npm install`** only for local exploratory work when not committing lockfile changes.

---

## Verification commands

Run from a **new terminal** after installation to ensure `PATH` is loaded.

```bash
git --version
docker --version
docker ps
kubectl version --client
helm version
node --version
npm --version
```

---

## Expected outputs (illustrative)

> Exact version strings depend on your install date and channel. You should see **non-empty version lines** and **no “command not found”** errors.

| Command | Expected pattern |
|---------|-------------------|
| `git --version` | `git version 2.x.x` |
| `docker --version` | `Docker version 27.x.x` or similar (Desktop or Engine) |
| `docker ps` | Table header + empty list or running containers; **no** daemon connection errors |
| `kubectl version --client` | `Client Version: ...` with valid `GitVersion` |
| `helm version` | `version.BuildInfo{Version:"v3.x.x", ...}` |
| `node --version` | `v20.x.x` (aligned with project) |
| `npm --version` | `10.x.x` or compatible with your Node 20 install |

---

## Screenshots and proof placeholders

Attach evidence to the sprint PR or store files under `docs/proofs/` using names such as:

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `git --version` | `docs/proofs/4.8-git-version.png` |
| 2 | `docker --version` | `docs/proofs/4.8-docker-version.png` |
| 3 | `docker ps` | `docs/proofs/4.8-docker-ps.png` |
| 4 | `kubectl version --client` | `docs/proofs/4.8-kubectl-version.png` |
| 5 | `helm version` | `docs/proofs/4.8-helm-version.png` |
| 6 | `node --version` | `docs/proofs/4.8-node-version.png` |
| 7 | `npm --version` | `docs/proofs/4.8-npm-version.png` |

> **Privacy:** Crop or redact machine name, internal registry URLs, or kubeconfig paths if sharing publicly.

---

## Common troubleshooting

| Symptom | Likely cause | Mitigation |
|--------|--------------|------------|
| `docker: command not found` | Docker not installed or not on `PATH` | Reinstall Docker Desktop / Engine; restart terminal |
| `Cannot connect to the Docker daemon` | Daemon not running or no permission | Start Docker Desktop; on Linux, `sudo systemctl start docker` or add user to `docker` group |
| `kubectl: command not found` | kubectl not installed or wrong shell profile | Reinstall; open new terminal; verify `which kubectl` |
| `helm: command not found` | Helm not on `PATH` | Reinstall Helm; confirm install location is exported |
| `error: You must be logged in to the server` | No valid kubeconfig / cluster | Expected on a fresh workstation until a cluster is configured; **client** install is still valid for 4.8 |
| Wrong `node` version | Multiple Node installs | Use `nvm use 20` or adjust `PATH` so Node 20 is first |
| `npm` permission errors (global installs) | Global prefix permissions | Prefer project-local `npx` / per-user npm prefix; avoid `sudo npm` |

---

## Validation checklist

Use this before marking the assignment complete.

- [ ] `git --version` succeeds; `user.name` / `user.email` configured for commits  
- [ ] `docker --version` succeeds; `docker ps` succeeds (daemon reachable)  
- [ ] `kubectl version --client` succeeds  
- [ ] `helm version` succeeds  
- [ ] `node --version` reports **v20.x** (or team-approved 20 LTS)  
- [ ] `npm --version` succeeds  
- [ ] Proof artifacts captured per `docs/proofs/README.md`  
- [ ] Branch `spr1-devops-workstation` pushed; PR opened for review  

---

## Learning outcome

After completing **Assignment 4.8 / A-01**, you can:

- Explain the **role of each tool** in the DocSync DevOps lifecycle (source control → container → cluster → automation).  
- **Verify** a workstation independently using version and connectivity checks.  
- **Triage** common install and `PATH` issues without blocking the rest of the sprint backlog.  

---

## References

- [Git Documentation](https://git-scm.com/doc)  
- [Docker Docs](https://docs.docker.com/)  
- [Kubernetes kubectl Install](https://kubernetes.io/docs/tasks/tools/)  
- [Helm Install](https://helm.sh/docs/intro/install/)  
- [Node.js Download](https://nodejs.org/)  
