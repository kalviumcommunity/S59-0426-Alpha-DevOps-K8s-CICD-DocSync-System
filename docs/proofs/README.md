# Proof artifacts (Sprint #3)

This directory holds **screenshots** or **sanitized terminal transcripts** that evidence completed coursework and operational checks. Do **not** commit secrets, kubeconfig contents, or internal credentials.

## Naming convention

Use a predictable prefix so reviewers can map proofs to assignments:

```text
docs/proofs/<assignment-id>-<topic>.png
```

Example: `4.8-git-version.png`

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

*Maintained by the DocSync sprint team.*
