# Assignment A-04 / 4.11 — Linux Filesystem Structure & Permissions for DevOps Workflows

**Repository:** `S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`  
**Sprint:** #3 — DevOps with Kubernetes & CI/CD  
**Primary owner:** Samarth  
**Branch / PR identifier:** `spr4-linux-permissions`  

---

## Assignment metadata

| Field | Value |
|-------|--------|
| **Assignment number** | **4.11** (tracker ID: **A-04**) |
| **Module reference** | **Module 4** — Linux foundations for automation: paths, ownership, and permission bits that affect CI runners, containers, and shell scripts |
| **Objective** | Map the **Linux filesystem** to DevOps tasks, explain **permission bits** and **`chmod` / `chown`**, relate them to **executable scripts** and security, and document commands used when working with this repository on Linux or macOS-like shells. |

---

## Linux filesystem overview

Linux organizes all resources under a single tree rooted at **`/`**. Paths are case-sensitive. **Mount points** attach storage (disks, tmpfs, cgroup hierarchies) at directories without drive letters—critical for containers where the process sees a curated view of the tree.

| Concept | Meaning for DevOps |
|---------|-------------------|
| **Everything is a file** | Processes, sockets, and devices appear as files; `read`/`write` semantics apply |
| **FHS** (Filesystem Hierarchy Standard) | Predictable layout across servers and CI images |
| **Current user** | Determines default file creation ownership and allowed operations |

---

## Important directories for DevOps

### `/home`

- **Purpose:** Personal directories for human users (e.g., `/home/alice`).  
- **DevOps use:** SSH sessions, Git config (`~/.gitconfig`), tool caches, local clones.  
- **Note:** Container workloads often use **`/root`** or a dedicated app user under `/home` or `/nonexistent` depending on image policy.

### `/etc`

- **Purpose:** System-wide configuration (static, often package-managed).  
- **DevOps use:** `hosts`, `resolv.conf`, `ssh/sshd_config`, package manager repos.  
- **Containers:** Often **ephemeral** or image-baked; Kubernetes mounts **ConfigMaps/Secrets** into paths under `/etc` or app-specific dirs.

### `/var`

- **Purpose:** Variable data: logs, caches, spool, databases.  
- **DevOps use:** `/var/log` for daemon logs; `/var/lib/docker` on Docker hosts.  
- **CI:** Ephemeral runners may still use `/var` for job workspaces and logs.

### `/tmp`

- **Purpose:** World-writable sticky area for short-lived files (`sticky bit` on the directory).  
- **DevOps use:** Quick extracts, socket files, build scratch.  
- **Risk:** **Never** store secrets in `/tmp` on shared systems; contents may be visible to other users depending on mount options.

### `/usr`

- **Purpose:** Read-only application hierarchy: `/usr/bin`, `/usr/lib`, `/usr/share`.  
- **DevOps use:** Installed binaries (`git`, `node`, `kubectl`); base image layers in OCI images often mirror this layout.

### `/opt`

- **Purpose:** Optional third-party or vendor software bundles.  
- **DevOps use:** Self-contained installs (e.g., `/opt/some-agent`); less common in minimal Alpine images than `/usr/local`.

---

## File permission basics

Each file has **three permission triplets** (read `r`, write `w`, execute `x`) for:

| Class | Applies to |
|-------|------------|
| **User (`u`)** | File owner |
| **Group (`g`)** | Members of the file’s group |
| **Others (`o`)** | Everyone else |

**Symbolic view:** `-rwxr-xr--` (leading `-` = regular file; `d` = directory).

**Numeric (octal) view:** three digits, e.g. **`755`** → `rwxr-xr-x` (owner read/write/execute; group/other read/execute).

| Octal | Bits | Typical use |
|-------|------|-------------|
| `644` | `rw-r--r--` | Config files, documentation |
| `755` | `rwxr-xr-x` | Directories, runnable scripts meant to be shared |
| `700` | `rwx------` | Private keys, sensitive dirs |

**Directories:** `x` on a directory means **enter / traverse** (e.g., `cd`); without `x`, listing may fail even with `r`.

---

## `chmod` explanation

**`chmod`** changes **mode bits** (who can read/write/execute).

| Form | Example | Effect |
|------|---------|--------|
| Symbolic | `chmod u+x script.sh` | Add execute for owner |
| Symbolic | `chmod go-w file.txt` | Remove write for group and others |
| Numeric | `chmod 644 README.md` | Owner rw; group/other r only |

**Recursive (directories):** `chmod -R 750 mydir` — use with care; wrong flags can lock you out or over-expose files.

---

## `chown` explanation

**`chown`** changes **owner** and optionally **group**: `chown user:group path`.

| Example | Effect |
|---------|--------|
| `sudo chown $USER:$USER file` | Give file to current user (common after `sudo` created files) |
| `chown root:root /etc/foo` | Typical system ownership (requires root) |

In DevOps, `chown` appears when fixing **volume mount** ownership in containers or when CI runs as a non-root user after a root step.

---

## Executable script permissions

Shell scripts (e.g., `scripts/pre-build-check.sh`) must have the **execute** bit set for direct invocation:

```bash
chmod +x scripts/pre-build-check.sh
./scripts/pre-build-check.sh
```

Without `+x`, you can still run `bash scripts/pre-build-check.sh` (interpreter reads the file—read permission required).

**Container note:** Dockerfile `COPY` does not always preserve host execute bits; some teams explicitly `RUN chmod +x` in the image build.

---

## Why permissions matter in DevOps

| Scenario | Risk if permissions are wrong |
|----------|--------------------------------|
| **CI pipeline** | Script not executable → failed job; overly open `644` on secrets → leak |
| **Kubernetes volumes** | UID/GID mismatch → **permission denied** on mounted data |
| **Docker** | Running as root in image vs non-root runtime expectations |
| **Production** | World-writable binaries or configs → supply-chain and integrity issues |

Principle of **least privilege:** grant the minimum mode bits and ownership required for the service user.

---

## Linux commands used in this project

| Command / pattern | Role in DocSync repo |
|-------------------|----------------------|
| `pwd`, `ls`, `cd` | Navigate repo root, `docs/`, `k8s/`, `scripts/` |
| `chmod +x scripts/*.sh` | Run pre-build checks locally (see `PROJECT_PROGRESS.md` §9) |
| `node`, `npm` | Invoked from shell and CI; not Linux-only but run on Linux runners |
| `tree` (optional) | Visualize structure for documentation (install if missing) |

Concrete workflow references: `PROJECT_PROGRESS.md` **§9 Commands Used**; assignment **4.8** for toolchain versions.

---

## Command examples

> Run from a terminal in or above the repository root unless noted. On macOS, behavior matches BSD userland for `ls`; GNU-specific flags may differ slightly.

### `pwd`

```bash
pwd
```

**Expected output:** absolute path to current directory, e.g. `/home/you/S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System`.

---

### `ls -la`

```bash
cd S59-0426-Alpha-DevOps-K8s-CICD-DocSync-System
ls -la
```

**Expected output:** lines with mode, links, owner, group, size, date, name; `.` and `..` entries; directories show leading `d`.

---

### `cd`

```bash
cd docs/assignments
pwd
```

**Expected output:** path ending in `.../docs/assignments`.

---

### `mkdir`

```bash
mkdir -p /tmp/docsync-lab/demo
ls -ld /tmp/docsync-lab/demo
```

**Expected output:** `drwx...` line for new directory.

---

### `touch`

```bash
touch /tmp/docsync-lab/demo/notes.txt
ls -l /tmp/docsync-lab/demo/notes.txt
```

**Expected output:** zero-byte file with current timestamp.

---

### `cat`

```bash
cat package.json | head -n 5
```

**Expected output:** first lines of `package.json` (JSON text).

---

### `chmod +x`

```bash
cp scripts/pre-build-check.sh /tmp/docsync-lab/demo/run.sh
chmod +x /tmp/docsync-lab/demo/run.sh
ls -l /tmp/docsync-lab/demo/run.sh
```

**Expected output:** mode includes `x` for owner (e.g. `-rwxr--r--` depending prior mode).

---

### `chown`

```bash
# Requires appropriate privileges; example uses sudo on multi-user Linux:
sudo chown "$(whoami):$(id -gn)" /tmp/docsync-lab/demo/notes.txt
ls -l /tmp/docsync-lab/demo/notes.txt
```

**Expected output:** owner/group reflect your user after change.

---

### `whoami`

```bash
whoami
id
```

**Expected output:** username; `id` shows uid, gid, and groups.

---

### `tree`

```bash
# Install if needed: e.g. brew install tree / sudo apt install tree
tree -L 2 -d docs
```

**Expected output:** ASCII tree of `docs` subdirectories (depth 2). If `tree` is missing, use `find docs -maxdepth 2 -type d`.

---

## Expected outputs (summary)

| Command | Success signal |
|---------|----------------|
| `pwd` | Prints one absolute path |
| `ls -la` | Lists `.`, `..`, and entries with permission string |
| `cd` | No error; `pwd` reflects new location |
| `mkdir -p` | Creates nested dirs; idempotent |
| `touch` | Creates or updates mtime |
| `cat` | Prints file contents to stdout |
| `chmod +x` | `ls -l` shows `x` in owner triplet for files that should run |
| `chown` | `ls -l` shows intended owner:group |
| `whoami` / `id` | Identity matches expectations for the session |
| `tree` | Directory hierarchy visible |

---

## Validation checklist

- [ ] Can sketch **`/`** and place `/home`, `/etc`, `/var`, `/tmp`, `/usr`, `/opt` from memory  
- [ ] Can read **`ls -l`** permission string for a file and a directory  
- [ ] Applied **`chmod +x`** and executed a script with `./`  
- [ ] Understood when **`chown`** / **`sudo`** is required vs dangerous  
- [ ] Captured **proof screenshots** per `docs/proofs/README.md` (Assignment 4.11)  
- [ ] Opened PR **`spr4-linux-permissions`** for review  

---

## Screenshots and proof placeholders

| # | Proof | Suggested filename |
|---|--------|--------------------|
| 1 | `pwd` in repo or lab directory | `docs/proofs/4.11-pwd.png` |
| 2 | `ls -la` showing modes | `docs/proofs/4.11-ls-la.png` |
| 3 | `ls -l` before/after `chmod +x` (or single frame with `+x` visible) | `docs/proofs/4.11-chmod-x.png` |
| 4 | Terminal running `./script.sh` after chmod | `docs/proofs/4.11-script-exec.png` |
| 5 | `ls -l` highlighting permissions on key files | `docs/proofs/4.11-file-permissions.png` |

---

## Learning outcome

After **Assignment 4.11 / A-04**, you can:

- Navigate the **standard Linux hierarchy** and choose appropriate locations for logs, config, and temp data.  
- Interpret and set **file permissions** with **`chmod`** and ownership with **`chown`**.  
- Explain why **execute bits** and **user/group** alignment matter for **CI, containers, and Kubernetes volumes**.  
- Use core shell commands (`pwd`, `ls`, `cd`, `mkdir`, `touch`, `cat`, `whoami`, `tree`) confidently in DocSync workflows.  

---

## References

- [Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)  
- `man chmod` · `man chown` · `man ls`  
- DocSync: `scripts/pre-build-check.sh`, `PROJECT_PROGRESS.md` §9  
