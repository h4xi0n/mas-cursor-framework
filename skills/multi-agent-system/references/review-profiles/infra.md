# Review Profile: Infrastructure & DevOps (`infra`)

Specialized domain checklist for reviewing Dockerfiles, CI/CD pipelines, Kubernetes manifests, and cloud infrastructure.

---

## Invariants

1. **Rootless Containers:** Containers must never execute as `root`. Dockerfiles must declare a dedicated non-root user (`USER nonroot` or `USER 10001`) and use multi-stage builds.
2. **Pinned CI/CD Actions:** Third-party GitHub Actions must be pinned to 40-character immutable Git commit SHAs (e.g. `actions/checkout@b4ffde...`), not mutable version tags (`@v4`).
3. **Zero Secret Leakage:** No plaintext credentials, API tokens, certificates, or SSH keys in repository files, environment configs, or Docker build arguments.
4. **Health & Lifecycle Probes:** Microservices and container workloads must declare both liveness (`/healthz`) and readiness (`/readyz`) probe endpoints.
5. **Least-Privilege RBAC:** Service account configurations, cloud IAM roles, and workflow permissions (`permissions: contents: read`) must enforce the principle of least privilege.

---

## Domain Checklist

Evaluate each item as `PASS`, `FAIL`, or `N/A`:

| Check Item | Requirement | Status | Notes |
|---|---|:---:|---|
| **Container Rootless User** | Dedicated non-root user declared before entrypoint execution. | | |
| **Multi-Stage & Slim Base** | Multi-stage Dockerfile using minimal base image (alpine/distroless). | | |
| **CI/CD Action SHA Pinning** | External actions pinned to 40-char immutable commit SHAs. | | |
| **Zero Secret Leaks** | Secrets injected via env/vault; no hardcoded keys in scripts. | | |
| **Health Probes** | Liveness and readiness endpoints defined in manifest or config. | | |
| **Resource Limits** | CPU and memory requests/limits defined in container manifests. | | |
| **Pipeline Failure Fast** | Shell scripts in CI use `set -euo pipefail` or `$ErrorActionPreference`. | | |

---

## Required Output Section

Render this section under `## Stage 2: Domain Deep-Dive (Profile: infra)`:

```markdown
## Platform & DevOps Infrastructure Verification

| Check | Status | Notes |
|-------|:------:|-------|
| Container Security (Non-root, multi-stage) | PASS / FAIL | <Dockerfile user and layer check> |
| CI/CD Action Pinning (40-char SHAs) | PASS / FAIL | <workflow action tags check> |
| Secret Hygiene & Configuration | PASS / FAIL | <credential leak scan> |
| Health Probes (/healthz, /readyz) | PASS / FAIL / N/A | <probe verification> |
| Least-Privilege Permissions | PASS / FAIL | <IAM/workflow permission check> |
```
