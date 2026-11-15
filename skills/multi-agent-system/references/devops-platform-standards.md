# DevOps & Platform Engineering Standards

Reference standards for [mas-devops](../../mas-devops/SKILL.md), [mas-architect](../../mas-architect/SKILL.md), [mas-security-auditor](../../mas-security-auditor/SKILL.md), and [mas-reviewer](../../mas-reviewer/SKILL.md) (Step 0o).

---

## 1. Multi-Stage Containerization Standards

Containers must be built with minimal attack surfaces, minimal final image sizes, and strict unprivileged execution.

### Non-Root Execution Invariant
Containers must **never** execute as `root` (UID 0). Every runtime container must create and switch to a dedicated unprivileged user (`appuser:10001:10001`).

### Multi-Stage Dockerfile Pattern

```dockerfile
# Stage 1: Build & Compilation
FROM gradle:8.7-jdk21-alpine AS builder
WORKDIR /app
COPY gradle/ gradle/
COPY gradlew build.gradle.kts settings.gradle.kts ./
RUN ./gradlew dependencies --no-daemon

COPY src/ src/
RUN ./gradlew bootJar --no-daemon

# Stage 2: Minimal Secure Runtime
FROM eclipse-temurin:21-jre-alpine AS runtime

# Create unprivileged system group and user
RUN addgroup -S -g 10001 appgroup && \
    adduser -S -u 10001 -G appgroup appuser

WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/build/libs/app.jar ./app.jar

# Run as non-root user
USER 10001:10001

# Healthcheck probe
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/healthz || exit 1

EXPOSE 8080
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

---

## 2. GitHub Actions CI/CD Security Hygiene

Workflows located in `.github/workflows/` must follow strict supply-chain security practices:

### Pinned Action Commits Invariant
All third-party GitHub Actions must be pinned to full 40-character immutable commit SHAs, with the semantic tag documented as a trailing comment. Never use floating mutable major version tags (e.g. `@v4`).

```yaml
# Good: Immutable commit SHA
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
- uses: actions/setup-java@8df1039502a140fb607e3ab18b173520d7fd4f94 # v4.5.0

# Bad: Mutable tag (Supply chain risk)
- uses: actions/checkout@v4
```

### Least-Privilege Permissions
Workflows must explicitly define minimal permissions at the top level or per job:

```yaml
permissions:
  contents: read
  packages: none
  pull-requests: none
```

---

## 3. Infrastructure as Code (IaC) Standards

All cloud infrastructure authored using Terraform or OpenTofu must satisfy:
1. **State Isolation**: Remote state storage (S3 / GCS) with mandatory state locking (DynamoDB table).
2. **Modular Architecture**: Separate reusable modules (`modules/vpc`, `modules/app_service`) from environment root configurations (`environments/dev`, `environments/prod`).
3. **Least Privilege IAM**: Restrict service accounts and IAM roles to the minimum permissions needed to operate.
4. **Validation Gate**: All Terraform changes must pass syntax and lint validation without errors:
   ```bash
   terraform fmt -check
   terraform validate
   ```

---

## 4. Environment Variables & Secrets Management

1. **Zero Secret Ingestion**: Plaintext secrets, private keys, passwords, and API tokens must **never** be committed to version control.
2. **Contract Specification (`.env.example`)**: Every service repository must provide an up-to-date `.env.example` documenting all required configuration keys, dummy placeholders, and descriptions.
3. **Runtime Injection**: Secrets must be injected at container startup from encrypted secret managers (GitHub Actions Secrets, AWS Secrets Manager, HashiCorp Vault, or Google Cloud Secret Manager).

---

## 5. Health Checks & Graceful Shutdown

1. **Liveness Probe (`/healthz`)**: Returns HTTP 200 OK if the process is running. Indicates whether container orchestrator needs to restart the container.
2. **Readiness Probe (`/readyz`)**: Returns HTTP 200 OK only when database connections and dependent downstream services are verified.
3. **Graceful Shutdown**: The application must catch `SIGTERM` signals and complete existing in-flight HTTP requests within a 30-second grace period before terminating.
