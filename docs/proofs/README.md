# Proof artifacts (Sprint #3)

This directory holds **screenshots** or **sanitized terminal transcripts** that evidence completed coursework and operational checks. Do **not** commit secrets, kubeconfig contents, or internal credentials.

## Naming convention

Use a predictable prefix so reviewers can map proofs to assignments:

```text
docs/proofs/<assignment-id>-<topic>.png
```

Example: `4.8-git-version.png`, `4.9-github-pr.png`, `4.10-git-status.png`, `4.11-ls-la.png`, `4.12-docker-ps.png`, `4.13-docker-history.png`, `4.14-docker-build.png`

---

## Assignment 4.8 / A-01 — DevOps workstation (`spr1-devops-workstation`)

**Related doc:** [`docs/assignments/A-01-devops-workstation.md`](../assignments/A-01-devops-workstation.md)

### Proof checklist

| # | Requirement | Command (or action) | Captured? |
|---|----------------|---------------------|-----------|
| 1 | Git installed | `git --version` | [ ] |
| 2 | Docker CLI / Engine | `docker --version` | [ ] |
| 3 | Docker daemon reachable | `docker ps` | [ ] |
| 4 | kubectl client | `kubectl version --client` | [ ] |
| 5 | Helm client | `helm version` | [ ] |
| 6 | Node.js (target v20 for DocSync) | `node --version` | [ ] |
| 7 | npm | `npm --version` | [ ] |

### Submission notes

- Prefer **PNG** or **PDF** exports; ensure text is readable at 100% zoom.  
- If using **light/dark** themes, maximize contrast for academic submission.  
- Link to this checklist from the PR description when opening **PR1** for review.  

---

## Assignment 4.9 / A-02 — DevOps principles & CI/CD (`spr2-devops-principles`)

**Related doc:** [`docs/assignments/A-02-devops-principles.md`](../assignments/A-02-devops-principles.md)

### Proof checklist

| # | Requirement | Command (or action) | Captured? |
|---|----------------|---------------------|-----------|
| 1 | Current Git branch | `git branch` or IDE branch indicator (screenshot) | [ ] |
| 2 | Commit on branch | `git log -1` or GitHub commit view for this branch | [ ] |
| 3 | GitHub Pull Request | PR page showing title, checks, reviewers (redact if needed) | [ ] |
| 4 | Repository workflow | GitHub **Actions** tab: workflow run for this repo/branch | [ ] |
| 5 | Recent history | `git log --oneline -n 10` (or equivalent graph) | [ ] |

### Submission notes

- For **workflow** proof, include the run **name**, **branch**, and **conclusion** (success/failure) in frame.  
- Link to this checklist from the PR description when opening **PR2** for review.  

---

## Assignment 4.10 / A-03 — Git workflow & conventions (`spr3-git-workflow`)

**Related doc:** [`docs/assignments/A-03-git-workflow.md`](../assignments/A-03-git-workflow.md)

### Proof checklist

| # | Requirement | Command (or action) | Captured? |
|---|----------------|---------------------|-----------|
| 1 | Git branches | `git branch` or GitHub branch dropdown | [ ] |
| 2 | Working tree state | `git status` | [ ] |
| 3 | Recent commits (terminal) | `git log --oneline -n 10` | [ ] |
| 4 | Commit history (GitHub UI) | Repository **Commits** tab for your branch | [ ] |
| 5 | PR creation | “Open pull request” / compare view for this branch | [ ] |

### Submission notes

- For **commit history** vs **git log**, include one terminal capture and one GitHub capture so reviewers can correlate SHAs.  
- Link to this checklist from the PR description when opening **PR3** for review.  

---

## Assignment 4.11 / A-04 — Linux filesystem & permissions (`spr4-linux-permissions`)

**Related doc:** [`docs/assignments/A-04-linux-permissions.md`](../assignments/A-04-linux-permissions.md)

### Proof checklist

| # | Requirement | Command (or action) | Captured? |
|---|----------------|---------------------|-----------|
| 1 | Current directory | `pwd` | [ ] |
| 2 | Detailed listing | `ls -la` (repo root or `scripts/`) | [ ] |
| 3 | Make script executable | `chmod +x <script>` then `ls -l` showing `x` | [ ] |
| 4 | Run script | `./scripts/pre-build-check.sh` or lab copy (terminal output) | [ ] |
| 5 | File permissions | `ls -l` on selected files (modes + owner readable) | [ ] |

### Submission notes

- For **script execution**, include the **command line** and **exit** (or success message) in frame.  
- Link to this checklist from the PR description when opening **PR4** for review.  

---

## Assignment 4.12 / A-05 — Containerization concepts (`spr5-containerization-concepts`)

**Related doc:** [`docs/assignments/A-05-containerization-concepts.md`](../assignments/A-05-containerization-concepts.md)

### Proof checklist

| # | Requirement | Command (or action) | Captured? |
|---|----------------|---------------------|-----------|
| 1 | Docker CLI / Engine version | `docker --version` | [ ] |
| 2 | Local images | `docker images` | [ ] |
| 3 | Running / all containers | `docker ps` and/or `docker ps -a` | [ ] |
| 4 | Lifecycle understanding | Screenshot of diagram or **§ Container lifecycle** in assignment doc / notes | [ ] |
| 5 | Project containerization narrative | `README.md` or related docs in IDE/browser (crop to relevant section) | [ ] |

### Submission notes

- For **lifecycle**, exporting a PDF or PNG from slides is acceptable if terminal-only proof is insufficient.  
- Link to this checklist from the PR description when opening **PR5** for review.  

---

## Assignment 4.13 / A-06 — Docker architecture (`spr6-docker-architecture`)

**Related doc:** [`docs/assignments/A-06-docker-architecture.md`](../assignments/A-06-docker-architecture.md)

### Proof checklist

| # | Requirement | Command (or action) | Captured? |
|---|----------------|---------------------|-----------|
| 1 | Client + Server versions | `docker version` | [ ] |
| 2 | Engine / driver summary | `docker info` (first screenful OK) | [ ] |
| 3 | Local images | `docker images` | [ ] |
| 4 | Containers | `docker ps` and/or `docker ps -a` | [ ] |
| 5 | Image layer history | `docker history <image-name>` | [ ] |
| 6 | Container metadata | `docker inspect <container-id>` | [ ] |

### Submission notes

- For **`docker inspect`**, JSON is long—crop to **State**, **Config**, or use `--format` in the screenshot caption.  
- Link to this checklist from the PR description when opening **PR6** for review.  

---

## Assignment 4.14 / A-07 — Dockerfile basics (`spr7-dockerfile-basics`)

**Related doc:** [`docs/assignments/A-07-dockerfile-basics.md`](../assignments/A-07-dockerfile-basics.md)

### Proof checklist

| # | Requirement | Command (or action) | Captured? |
|---|----------------|---------------------|-----------|
| 1 | Dockerfile source | IDE / GitHub view of `Dockerfile` | [ ] |
| 2 | Successful image build | `docker build -t docsync:basic .` (tail output) | [ ] |
| 3 | Image present locally | `docker images` (show `docsync:basic`) | [ ] |
| 4 | Running container | `docker run --rm -p 3000:3000 docsync:basic` (logs or second terminal) | [ ] |
| 5 | Health endpoint | `curl http://localhost:3000/health` or browser | [ ] |

### Submission notes

- Redact registry credentials or internal hostnames if visible in terminal tabs.  
- Link to this checklist from the PR description when opening **PR7** for review.  

---

*Maintained by the DocSync sprint team.*
