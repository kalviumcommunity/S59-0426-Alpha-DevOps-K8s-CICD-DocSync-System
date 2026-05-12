# DocSync — image tagging strategy (GHCR)

This document describes how DocSync container images should be **tagged** when published to **GitHub Container Registry (GHCR)** and how that supports **rollbacks** and **CI/CD**. It complements [`../assignments/A-11-docker-registry-ghcr.md`](../assignments/A-11-docker-registry-ghcr.md).

---

## Tag formats

| Format | Example | Typical producer |
|--------|---------|------------------|
| **Commit SHA (short)** | `sha-a1b2c3d` | CI (`docker/metadata-action`, BuildKit annotations) |
| **Semantic version** | `v1.2.0`, `1.2.0` | Release workflow / manual promotion |
| **Branch / environment** | `main`, `dev`, `local-dev` | Ad-hoc or teaching labs |
| **Mutable pointer** | `latest` | CI default (convenience, not for prod alone) |
| **Digest reference** | `ghcr.io/org/repo@sha256:…` | Immutable deploy pin (strongest guarantee) |

---

## Examples (illustrative)

```text
ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system:sha-424e6c1
ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system:v1.2.0
ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system:latest
ghcr.io/kalviumcommunity/s59-0426-alpha-devops-k8s-cicd-docsync-system:local-dev
```

> Use the exact package path from **GitHub → Packages**; Docker references are **lowercase** for `ghcr.io` paths.

---

## When to use `latest`

| Use `latest` | Avoid relying on `latest` alone when … |
|--------------|----------------------------------------|
| Quick smoke tests, local iteration | You need **auditability** (which commit is running?) |
| Demos / coursework drafts | Doing **rollbacks** (tag may move) |
| Default pull for anonymous public images | Enforcing **immutable releases** in production |

**Rule of thumb:** `latest` is a **pointer**, not a contract. Pair it with **digest** or **semver** for anything customer-facing.

---

## When to use commit SHA (or digest)

| Benefit | Explanation |
|---------|-------------|
| **Immutability** | SHA/digest maps 1:1 to image bits |
| **Traceability** | Links artifact to Git commit in GitHub UI |
| **Safer rollback** | Re-deploy previous digest without guessing |

CI should emit **both** a human tag (`v1.2.0`) and a **digest** in job summaries (see repository GitHub Actions workflow).

---

## Rollback benefits

1. **Kubernetes:** change image field to previous **digest** or semver tag → rollout undo.  
2. **Registry:** old layers remain reachable by old tags until garbage-collected.  
3. **Blame:** incident review ties failing revision to CI run and commit.

---

## Production recommendation

| Practice | Detail |
|----------|--------|
| **Pin by digest** in prod manifests | `image: ghcr.io/org/repo@sha256:…` |
| **Promote semver** for humans | `v1.2.3` tags on merge to protected branch |
| **Avoid solo `latest`** | If used, always record digest in deploy notes |
| **Scope tokens** | PAT / `GITHUB_TOKEN` minimal scopes; short TTL |
| **Sign / attest** (future) | SLSA / cosign for higher assurance |

---

## Related scripts

- [`../../scripts/docker-tag-ghcr.sh`](../../scripts/docker-tag-ghcr.sh) — local build + `docker tag` helper; **does not** push or log in.

---

*Maintained by the DocSync sprint team.*
