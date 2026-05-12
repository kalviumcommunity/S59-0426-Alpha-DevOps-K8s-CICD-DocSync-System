# Assignment A-03 / 4.10 — Git Repositories, Branching Models, and Commit Conventions

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr3-git-workflow`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.10** (tracker ID: **A-03**) |
| **Module reference** | **Module 4** — Version control, collaborative workflows, and conventions that keep DocSync changes reviewable and traceable |
| **Objective** | Describe how **Git** and **GitHub** support team delivery; document **branching**, **commit conventions**, and the **pull request** workflow used in this sprint; equip teammates to work safely with **history**, **status**, and basic **merge conflicts**. |

---

## Introduction to Git and GitHub

**Git** is a distributed version control system: every clone carries full history, branches are cheap pointers, and commits form an immutable directed graph (rewriting history is possible but should be deliberate).

**GitHub** adds collaboration and automation: hosted remotes, pull requests, reviews, checks (CI), and protected branches. For DocSync, GitHub is the **system of record** for code reviews and the trigger surface for GitHub Actions.

| Concept | Role |
|---------|------|
| **Repository** | Project root tracked by `.git/` metadata |
| **Remote** | `origin` → GitHub URL for push/pull |
| **Branch** | Line of development; default integration branch is **`main`** |
| **Commit** | Snapshot of tracked files with author, message, parent SHA |

---

## Repository structure overview

DocSync uses a **single repository** (“monorepo”) layout: application code, Kubernetes manifests, CI workflows, and documentation live together so one PR can span related changes (with clear scope).

| Area | Typical paths |
|------|----------------|
| **Application** | `src/`, `tests/`, `package.json` |
| **Containers** | `Dockerfile`, `.dockerignore` |
| **Kubernetes** | `k8s/` |
| **CI/CD** | `.github/workflows/` |
| **Docs & sprint artifacts** | `docs/`, `PROJECT_PROGRESS.md` |

> Full tree: see **§7 Repository Structure** in [`PROJECT_PROGRESS.md`](../../PROJECT_PROGRESS.md) or the repository `README.md`.

---

## Branching models

### `main` branch

- **Purpose:** integration-ready, deployable-by-policy code for DocSync.  
- **Rules (recommended):** require PR reviews, passing CI, linear history or squash merge per team policy.  
- **Do not** push experimental work directly to `main` during the sprint—use feature branches.

### Feature branches

- **Purpose:** isolate one assignment, bugfix, or feature (e.g., `spr3-git-workflow`).  
- **Naming:** short, predictable prefixes (`spr`, `feat`, `fix`) + topic.  
- **Lifetime:** delete after merge (local + remote) to reduce clutter.

### PR workflow

```text
main (updated) → checkout -b feature → commit → push → open PR → review/CI → merge → delete branch
```

Each PR should have a **clear title**, **summary**, **test plan**, and links to tracker rows (e.g., `PROJECT_PROGRESS.md` §8).

---

## Git workflow used in this project

| Step | Practice |
|------|----------|
| 1 | `git fetch` / `git pull` on `main` before branching |
| 2 | Create branch per sprint PR (`sprN-…`) |
| 3 | Small, focused commits with conventional messages |
| 4 | Push branch; open PR into `main` |
| 5 | Address review; ensure checks green |
| 6 | Merge; pull latest `main` locally |

This mirrors industry **trunk-based** tendencies: short-lived branches, frequent integration, automation on `main`.

---

## Commit conventions

A practical convention for this course (compatible with **Conventional Commits**):

```text
<type>(<scope>): <short description>

[optional body]
```

| `type` | When to use |
|--------|-------------|
| `docs` | Documentation only (`docs/`, `PROJECT_PROGRESS.md`) |
| `chore` | Tooling, formatting, non-functional changes |
| `feat` | New behavior |
| `fix` | Bug fix |
| `ci` | CI workflow changes (avoid in doc-only sprints if restricted) |

**Examples**

```text
docs(sprint3): add A-03 git workflow assignment
fix(k8s): correct service port mapping
feat(api): add document export endpoint
```

---

## Importance of clean commits

| Benefit | Explanation |
|---------|-------------|
| **Reviewability** | Reviewers can follow intent commit-by-commit |
| **Blame / bisect** | `git bisect` finds regressions faster with atomic commits |
| **Revert safety** | `git revert` targets a single logical change |
| **Audit trail** | Course staff can map work to assignments and PRs |

**Anti-patterns:** “WIP”, “fix”, “asdf” messages; giant commits mixing unrelated files; committing secrets or `node_modules/`.

---

## Pull Request workflow

| Stage | Owner actions |
|-------|----------------|
| **Draft (optional)** | Early feedback without merge pressure |
| **Ready for review** | Complete checklist, add screenshots/proofs |
| **Review** | Teammate(s) comment; request changes or approve |
| **Checks** | CI must pass (lint/test/build per workflow) |
| **Merge** | Squash or merge commit per policy; delete branch |

Link PR to **proof checklist** in `docs/proofs/README.md` when submitting coursework.

---

## Git collaboration process

1. **Communicate scope** in PR description (what changed, what did not).  
2. **Pull before push** if `main` moved: `git checkout main && git pull` then rebase or merge feature branch.  
3. **Respond to feedback** with additional commits or amended commits (only if team allows force-push).  
4. **Tag releases** only when course/instructor requires semver tags; otherwise rely on merge commits and SHAs.

---

## Merge conflict basics

**When:** two branches edit the same lines of the same file.

**Symptoms:** `git merge` or `git pull` stops with “CONFLICT”.

**Resolution (high level)**

1. Run `git status` — files listed as “both modified”.  
2. Open files, find conflict markers:

```text
<<<<<<< HEAD
your version
=======
their version
>>>>>>> branch-name
```

3. Edit to final intended content; **remove markers**.  
4. `git add <file>` then `git commit` (or continue rebase with `git rebase --continue`).

**Prevention:** smaller PRs, communicate on shared files, pull `main` frequently.

---

## Git best practices

- [ ] Branch from up-to-date `main`  
- [ ] Commit often; push at least once before end of day on shared work  
- [ ] Write messages that explain **why**, not only **what**  
- [ ] Keep PRs small and single-purpose  
- [ ] Never commit secrets—use GitHub **Secrets** for CI  
- [ ] Use `.gitignore` for build artifacts and local OS files  

---

## Commands used

Below are **copy-pasteable** examples. Replace placeholders (`<url>`, `<branch>`, etc.) with your values.

### `git clone`

```bash
git clone https://github.com/<org>/S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System.git
cd S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System
```

**Expected:** new directory with `.git/`, remote `origin` set.

---

### `git checkout -b`

```bash
git checkout main
git pull origin main
git checkout -b spr3-git-workflow
```

**Expected:** `Switched to a new branch 'spr3-git-workflow'`.

---

### `git status`

```bash
git status
```

**Expected:** branch name, ahead/behind hints, staged/untracked lists.

---

### `git add`

```bash
git add docs/assignments/A-03-git-workflow.md
git add docs/proofs/README.md PROJECT_PROGRESS.md
```

**Expected:** paths move to “Changes to be committed”.

---

### `git commit`

```bash
git commit -m "docs(sprint3): add A-03/4.10 git workflow assignment"
```

**Expected:** commit SHA printed; working tree clean for tracked files.

---

### `git push`

```bash
git push -u origin spr3-git-workflow
```

**Expected:** branch appears on GitHub; upstream tracking set.

---

### `git pull`

```bash
git checkout main
git pull origin main
```

**Expected:** fast-forward or merge commit; local `main` matches remote.

---

### `git log`

```bash
git log --oneline -n 10
git log --graph --decorate --oneline -n 15
```

**Expected:** chronological commits with SHAs and messages.

---

## Expected outputs (summary)

| Command | What “good” looks like |
|---------|-------------------------|
| `git clone` | Repo folder created; `git remote -v` shows `origin` |
| `git checkout -b` | New branch; prompt/IDE reflects branch name |
| `git status` | Clear staged vs unstaged; no surprise secrets |
| `git add` / `git commit` | Commit recorded; `git log -1` shows message |
| `git push` | Remote branch updated; PR can be opened |
| `git pull` | No errors; `main` updated |
| `git log` | Readable history; sprint branches visible in graph |

---

## Validation checklist

- [ ] Cloned DocSync repo and verified `origin` remote  
- [ ] Created assignment branch from current `main`  
- [ ] Committed documentation with a **conventional** message  
- [ ] Pushed branch and opened **PR into `main`**  
- [ ] Captured proofs listed in `docs/proofs/README.md` (Assignment 4.10)  
- [ ] Updated `PROJECT_PROGRESS.md` §8 row **A-03** to this PR / **In Review**  

---

## Screenshots and proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `git branch` (feature branch visible) | `docs/proofs/4.10-git-branch.png` |
| 2 | `git status` (clean or staged before commit) | `docs/proofs/4.10-git-status.png` |
| 3 | `git log` (recent commits) | `docs/proofs/4.10-git-log.png` |
| 4 | GitHub **Commits** / history on branch | `docs/proofs/4.10-commit-history.png` |
| 5 | GitHub **Open PR** (create/compare view) | `docs/proofs/4.10-pr-creation.png` |

---

## Learning outcome

After **Assignment 4.10 / A-03**, you can:

- Explain **Git vs GitHub** and the role of **branches** and **PRs** in DocSync.  
- Follow the sprint **branch naming** and **merge-back** pattern safely.  
- Use **status/log** to inspect work and produce **evidence** for coursework.  
- Resolve simple **merge conflicts** using a repeatable sequence.  

---

## References

- [Git Book](https://git-scm.com/book/en/v2)  
- [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow)  
- [Conventional Commits](https://www.conventionalcommits.org/)  
