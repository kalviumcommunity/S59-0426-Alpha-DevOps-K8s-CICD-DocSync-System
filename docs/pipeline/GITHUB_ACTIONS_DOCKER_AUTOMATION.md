# GitHub Actions + Docker automation (DocSync)

**Workflow file:** [`.github/workflows/ci-cd.yml`](../../.github/workflows/ci-cd.yml)  
**Assignment:** [`../assignments/A-20-github-actions-docker.md`](../assignments/A-20-github-actions-docker.md) (**4.37–4.40 / A-20**)  

This document explains **how** the repository automates **CI**, **Docker builds**, **GHCR pushes**, and the **optional** CD scaffold—without duplicating secrets in documentation.

---

## Workflow stage explanation

| Stage (logical) | GitHub Actions implementation |
|-----------------|------------------------------|
| **Source** | `actions/checkout@v4` in each job that needs the repo |
| **Install + verify** | `actions/setup-node@v4` (Node **20**) → `npm ci` → `npm run lint` → `npm test` in job **`ci`** |
| **Build + publish** | `docker/login-action` → `docker/metadata-action` → `docker/build-push-action` in **`build-and-push`** |
| **CD** | Job **`deploy-and-verify`**: **scaffold** by default; **live `kubectl`** only when **`KUBECONFIG_B64`** secret is configured |

---

## Trigger explanation

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

| Event | Why |
|-------|-----|
| **`pull_request`** | Validates contributor branches **before** merge; **no** registry push (saves quota / avoids untrusted code publishing) |
| **`push` to `main`** | Represents **integrated** line-of-business code → **build and push** allowed |

Conditional gates:

```yaml
if: github.event_name == 'push' && github.ref == 'refs/heads/main'
```

---

## Job dependency flow

```text
        pull_request / push
                 │
                 ▼
              ┌──────┐
              │  ci  │
              └──┬───┘
                 │ success
                 ▼ (push main only)
        ┌─────────────────┐
        │ build-and-push  │
        └────────┬────────┘
                 │ success (push main only)
                 ▼
      ┌──────────────────────┐
      │ deploy-and-verify    │
      └──────────────────────┘
```

---

## Docker build / push explanation

| Step | Action | Output |
|------|--------|--------|
| **Login** | `docker/login-action` to `ghcr.io` | Session for push |
| **Metadata** | `docker/metadata-action` | Tags + OCI labels (version, revision, source URL) |
| **Build+Push** | `docker/build-push-action` with `push: true` | Image stored at **`ghcr.io/${{ github.repository }}`** |

**Permissions**

```yaml
permissions:
  contents: read
  packages: write
```

`packages: write` is the **minimal** expansion needed for GHCR push using `GITHUB_TOKEN`.

---

## GHCR authentication explanation

| Input | Value |
|-------|--------|
| **Registry** | `ghcr.io` |
| **Username** | `${{ github.actor }}` (the user or bot that triggered the run) |
| **Password** | `${{ secrets.GITHUB_TOKEN }}` (**auto-provided**, rotated per job) |

**Safety notes**

- Never `echo` the token or kubeconfig.  
- Do **not** embed PATs in YAML.  
- Prefer **`GITHUB_TOKEN`** for student/course repos; adopt **OIDC** + cloud roles for advanced production setups (out of scope here).

---

## Image tag examples

After a successful `main` build you should see tags similar to:

| Tag example | Meaning |
|-------------|---------|
| `latest` | Newest green build on `main` (mutable) |
| `a1b2c3d` | Short **Git SHA** from `docker/metadata-action` (`type=sha,format=short`) |

Inspect remotely (requires `docker login`):

```bash
docker buildx imagetools inspect ghcr.io/<org>/<repo>:latest
```

---

## Optional live Kubernetes apply

| Condition | Behavior |
|-----------|----------|
| **Secret unset** | Prints **scaffold** commands referencing `k8s/deployment.yaml` and `k8s/service.yaml` |
| **`KUBECONFIG_B64` set** | Decodes kubeconfig, installs `kubectl`, runs `kubectl apply` + `kubectl rollout status` |

Encode locally (example):

```bash
base64 < ~/.kube/config | tr -d '\n'   # paste into GitHub → Settings → Secrets → Actions
```

**Never** commit the raw kubeconfig file.

---

## Failure handling quick reference

| Symptom | Likely cause |
|---------|----------------|
| `permission_denied` on push | Missing `packages: write` on job |
| `npm ci` fails | Lockfile out of sync with `package.json` |
| Docker build fails | Dockerfile / context error |
| `kubectl` fails in optional path | Invalid/expired kubeconfig; RBAC denies apply |

---

## Related documents

| Path | Role |
|------|------|
| [`PIPELINE_STAGES.md`](PIPELINE_STAGES.md) | Cross-stage table |
| [`../PIPELINE_DESIGN.md`](../PIPELINE_DESIGN.md) | Narrative pipeline design |
