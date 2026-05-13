---
name: docker
description: Optimize Docker images with multi-stage builds, distroless bases, BuildKit cache mounts, layer caching, multi-arch builds, security hardening (non-root, seccomp, capabilities), and docker-compose for local dev. Use when user asks to write a Dockerfile, optimize image size, set up docker-compose, debug containers, or harden container security. Do NOT use for Kubernetes deployments (use kubernetes), CI/CD pipeline design (use ci-cd), or Terraform infrastructure (use terraform).
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "2.0"
---

# Docker Architect

Production-grade Dockerfiles, multi-stage builds, cache optimization, security hardening, and local development with docker-compose.

## Workflow

### Step 1: Identify stack

Language, build tools, runtime requirements, base image preference.

### Step 2: Apply golden template

Use multi-stage builds:
```
Stage 1 (deps):   COPY lock files → install production deps
Stage 2 (build):  COPY source → compile
Stage 3 (runtime): minimal base → COPY artifacts from stages 1-2
```

### Step 3: Optimize (in order)

1. **Multi-stage**: Separate build from runtime. Never ship a compiler.
2. **Base image**: Distroless > Alpine > Slim. Match to runtime needs.
3. **Layer order**: Dependencies before source code. Maximize cache hits.
4. **BuildKit**: `RUN --mount=type=cache` for package managers, `--mount=type=secret` for secrets.
5. **Security**: Non-root, no shell in runtime, read-only rootfs, healthchecks.

## Production Dockerfiles

### Node.js

```dockerfile
FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

FROM node:22-slim AS builder
WORKDIR /app
COPY package.json package-lock.json tsconfig.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY src ./src
RUN npm run build

FROM gcr.io/distroless/nodejs22-debian12
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
EXPOSE 3000
USER nonroot
CMD ["dist/index.js"]
```

### Go

```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server .

FROM scratch
COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
CMD ["/server"]
```

### Python

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip pip install --user -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY src ./src
ENV PATH=/root/.local/bin:$PATH
EXPOSE 8000
USER nobody
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0"]
```

### Rust

```dockerfile
FROM rust:1.78-slim AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release 2>/dev/null || true
COPY src ./src
RUN cargo build --release

FROM gcr.io/distroless/cc-debian12
COPY --from=builder /app/target/release/app /app
CMD ["/app"]
```

## Dockerfile Rules

| Rule | Why |
|------|-----|
| Pin base image versions (`node:22-slim`, not `node:latest`) | Reproducible builds |
| COPY package files BEFORE source code | Layer caching |
| Combine `apt-get update && apt-get install` in one RUN | Avoids stale cache layers |
| Use `--no-install-recommends` | 20-40% image size reduction |
| Never put secrets in ENV or ARG | Leaks in `docker history` |
| Add `HEALTHCHECK` | Orchestrator detects failures |
| Set `USER nonroot` (not root) | Security best practice |
| Use `.dockerignore` | Smaller build context, faster builds |

## Multi-Architecture Builds

```bash
# Create builder with QEMU support
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag registry/app:latest \
  --push .
```

## Docker Compose Watch (hot reload)

```yaml
services:
  app:
    build: .
    ports: ["3000:3000"]
    develop:
      watch:
        - action: sync
          path: ./src
          target: /app/src
          ignore:
            - node_modules/
            - "*.test.ts"
        - action: rebuild
          path: package.json
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/app
    depends_on: [db]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      retries: 3

  db:
    image: postgres:16-alpine
    volumes: ["pgdata:/var/lib/postgresql/data"]
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: app

volumes:
  pgdata:
```

Run: `docker compose watch`

## Security Hardening

### Reduce container capabilities

```dockerfile
# Deny all, then allow specific
RUN setcap cap_net_bind_service=+ep /app/server
USER nonroot
```

In Kubernetes:
```yaml
securityContext:
  capabilities:
    drop: [ALL]
    add: [NET_BIND_SERVICE]
  readOnlyRootFilesystem: true
  runAsNonRoot: true
```

### Debug and security scanning

| Tool | Purpose | Command |
|------|---------|---------|
| `docker scout` | Vulnerability scanning | `docker scout cves <image>` |
| `dive` | Layer inspection | `dive <image>` |
| `trivy` | Comprehensive scanning | `trivy image <image>` |
| `cosign` | Image signing and verification | `cosign sign --key cosign.key <image>` |

### SLSA provenance

```bash
docker buildx build --attest type=provenance,mode=max --push -t registry/app:latest .
```

## Image Size Reference

| Stack | Single-stage | Multi-stage + Distroless |
|-------|-------------|-------------------------|
| Go | ~800MB | ~12-25MB (scratch) |
| Node.js | ~1.2GB | ~90-180MB |
| Python | ~1GB | ~120-200MB |
| Rust | ~1.5GB | ~20-50MB (cc) |
| Java | ~700MB | ~150-250MB |

## Debugging

| Problem | Command |
|---------|---------|
| Inspect layers | `docker history --no-trunc <image>` |
| Check disk usage | `docker system df` |
| Shell into container | `docker exec -it <container> /bin/sh` |
| Inspect build cache | `docker builder prune --dry-run` |
| Scan CVEs | `docker scout cves <image>` |
| View logs | `docker logs --tail 100 -f <container>` |
| Copy file from container | `docker cp <container>:/path/file ./local` |

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Single-stage with full OS | Multi-stage + distroless/alpine |
| `COPY . .` before `npm install` | COPY package files first, then `npm ci`, then source |
| `latest` tag | Pin semantic version or commit SHA |
| Running as root | `USER nonroot` |
| Secrets in build args | `--mount=type=secret` |
| No `.dockerignore` | Add one — exclude node_modules, .git, .env, build cache |
| Multiple FROMs without names | Name each stage: `AS builder`, `AS deps`, `AS runtime` |

## Sources

- Docker Documentation (docs.docker.com)
- Docker Best Practices Guide
- BuildKit Documentation
- Google Distroless Base Images
- Trivy Vulnerability Scanner (aquasecurity.github.io/trivy)
- SLSA Framework (slsa.dev)
