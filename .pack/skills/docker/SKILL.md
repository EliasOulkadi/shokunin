---
name: docker
description: Optimize Docker images with multi-stage builds, distroless bases, BuildKit cache mounts, multi-arch builds, compose watch, security hardening (non-root, seccomp, capabilities drop), and vulnerability scanning via docker scout/trivy. Use when user asks to write a Dockerfile, optimize image size, set up docker-compose, debug containers, harden container security, or scan for CVEs. Do NOT use for Kubernetes deployments (use kubernetes), CI/CD pipeline design (use ci-cd), or Terraform (use terraform).
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write
---

# Docker Architect

Production-grade Dockerfiles, multi-stage builds, cache optimization, security scanning, and local development. Applies Google's distroless philosophy and Docker BuildKit best practices.

## Workflow

### Quick start: `docker init`

For new projects, run `docker init` in the project root. It auto-detects the language/framework and generates a Dockerfile, `.dockerignore`, and `compose.yaml` with best-practice defaults. Always review and harden the output — the generated files are a starting point, not production-ready.

### Step 1: Identify stack and choose template

| Stack | Base image | Build stage | Runtime |
|-------|-----------|-------------|---------|
| Node.js | node:22-slim | Full SDK | gcr.io/distroless/nodejs |
| Go | golang:1.23-alpine | Full SDK | scratch |
| Python | python:3.12-slim | Full SDK | python:3.12-slim |
| Rust | rust:1.78-slim | Full SDK | gcr.io/distroless/cc |

**Decision**: If the stack is listed above, use the corresponding production Dockerfile below. If not, apply the golden template in Step 2.

### Step 2: Apply golden template

Use multi-stage with this exact structure:
```
Stage 1 (deps):   COPY lock files → install production deps (--mount=type=cache)
Stage 2 (build):  COPY source → compile
Stage 3 (runtime): minimal base → COPY artifacts from stages 1-2 → USER nonroot → HEALTHCHECK
```

**If the project is a Go binary**, skip Stage 1 (Go has no runtime deps) and go straight to Stage 2.

**If the project has native dependencies** (node-gyp, C extensions), use `apt-get` in the builder stage, NOT the runtime stage.

### Step 3: Apply BuildKit optimizations

```dockerfile
# syntax=docker/dockerfile:1.4
FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

FROM node:22-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY src ./src
RUN npm run build

FROM gcr.io/distroless/nodejs22-debian12
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
EXPOSE 3000
USER nonroot
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["node", "-e", "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1))"]
CMD ["dist/index.js"]
```

Run `scripts/optimize-dockerfile.sh` on any existing Dockerfile to receive optimization suggestions.

### Step 4: Configure compose for local dev

```yaml
services:
  app:
    build: .
    ports: ["3000:3000"]
    develop:
      watch:
        - action: sync+restart
          path: ./src
          target: /app/src
    depends_on: [db]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  db:
    image: postgres:16-alpine
    volumes: ["pgdata:/var/lib/postgresql/data"]
volumes: { pgdata: }
```

Run `docker compose watch` for hot-reload.

See [assets/docker-compose.template.yml](assets/docker-compose.template.yml) for the full template with all services.

### Step 5: Build for multiple platforms

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from=type=gha \
  --cache-to=type=gha,mode=max \
  --tag registry/app:latest \
  --push .
```

See [references/multi-arch.md](references/multi-arch.md) for QEMU setup and platform-specific optimizations.

### Step 6: Scan for vulnerabilities

```bash
# Using the provided script
scripts/scan-image.sh registry/app:latest

# Or manually:
docker scout cves registry/app:latest
trivy image registry/app:latest
```

**If critical CVEs are found**: either switch base image (e.g., distroless), or add apt-get to install patched deps in builder stage.

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `failed to solve with frontend dockerfile.v0` | Missing syntax directive | Add `# syntax=docker/dockerfile:1.4` as first line |
| `exec /usr/bin/node: exec format error` | Wrong platform | Build with `--platform linux/amd64` matching the target |
| `permission denied` at runtime | Missing `USER nonroot` or wrong file permissions | Add `USER nonroot` and `COPY --chown=nonroot:nonroot` |
| Layer cache miss every build | Changing files copied before lock files | Always `COPY package.json` BEFORE source code |
| `docker compose watch` not working | Docker Engine < 24 | Upgrade Docker Engine or use `docker compose up --watch` |

## Production Checklist

- [ ] Multi-stage build (build deps ≠ runtime deps)
- [ ] Distroless or scratch runtime (no shell, no package manager)
- [ ] `# syntax=docker/dockerfile:1.4` for BuildKit features
- [ ] `RUN --mount=type=cache` for package managers
- [ ] `RUN --mount=type=secret` for build secrets
- [ ] `USER nonroot` in runtime stage
- [ ] `HEALTHCHECK` defined
- [ ] `.dockerignore` excludes node_modules, .git, .env
- [ ] Base image version pinned (not `latest`)
- [ ] `docker scout cves` passes (zero critical)
- [ ] Multi-arch build for amd64 + arm64
- [ ] No secrets in `ARG` or `ENV` (use `--mount=type=secret`)

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Single-stage with full OS | Multi-stage + distroless |
| `COPY . .` before `npm install` | Lock files first, then source |
| `latest` tag | Pin SHA or semantic version |
| Running as root | `USER nonroot` |
| Secrets in build args | `--mount=type=secret` |
| No `.dockerignore` | Add one — exclude dev files |
| No healthcheck | Orchestrator can't detect failures |
| pinning only major version | Pin full version tag (`22.14-slim` not `22-slim`) |

## Sources

- Dockerfile best practices (docs.docker.com)
- BuildKit documentation
- Google distroless images
- Trivy vulnerability scanner
- Docker Scout documentation
- SLSA framework (slsa.dev)
