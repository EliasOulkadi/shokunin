---
name: docker
description: Optimize Docker images with multi-stage builds, distroless bases, BuildKit cache mounts, layer caching, security hardening, and docker-compose for local dev. Use when user asks to write a Dockerfile, optimize image size, set up docker-compose, debug containers, or harden container security. Triggers on "Dockerfile", "docker build", "docker-compose", "container", "multi-stage build", "image size", "distroless", "buildkit", "docker security". Do NOT use for Kubernetes deployments, Terraform infrastructure, or CI/CD pipeline design — those have their own skills.
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: developers
---

Expert guide to Docker containers: production-grade Dockerfiles, multi-stage builds, layer optimization, security hardening, and docker-compose for local development.

## Workflow

### Step 1: Determine the stack

Identify: language (Node.js, Go, Python, Rust, Java), build tools needed, runtime requirements.

### Step 2: Apply the golden template

Use multi-stage builds with this structure:
```
Stage 1 (dependencies): COPY package files → install
Stage 2 (build): COPY source → compile
Stage 3 (runtime): minimal base → COPY artifacts from stages 1-2
```

### Step 3: Optimize

Apply in order:
1. **Multi-stage**: Separate build from runtime. Never ship a compiler in production.
2. **Base image**: Distroless > Alpine > Slim > Full. Match to runtime needs.
3. **Layer order**: Dependencies before source code. Maximize cache hits.
4. **BuildKit**: `RUN --mount=type=cache` for package managers. `--mount=type=secret` for secrets.
5. **Security**: Non-root user, no shell in runtime, read-only rootfs, health checks.

## Production Dockerfile by Stack

### Node.js
```dockerfile
# syntax=docker/dockerfile:1.4
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

## Dockerfile Rules

| Rule | Why |
|------|-----|
| Pin base image versions (`node:22-slim` not `node:latest`) | Reproducible builds |
| COPY package files BEFORE source code | Layer caching — deps only rebuild when package.json changes |
| Combine `apt-get update && apt-get install` in one RUN | Avoids stale cache layers |
| Use `--no-install-recommends` | Reduces image size 20-40% |
| Never put secrets in ENV or ARG | Leaks in `docker history` |
| Add `HEALTHCHECK` | Orchestrators detect failures |
| Set `USER nonroot` (not root) | Security best practice |
| Use `.dockerignore` | Smaller build context, faster builds |

## Docker Compose for Local Dev

```yaml
services:
  app:
    build: .
    ports: ["3000:3000"]
    volumes: [".:/app", "/app/node_modules"]
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

## Debugging

| Problem | Command |
|---------|---------|
| Inspect layers | `docker history --no-trunc <image>` |
| Check size | `docker system df` |
| Shell into running container | `docker exec -it <container> /bin/sh` |
| Inspect build cache | `docker builder prune --dry-run` |
| Scan vulnerabilities | `docker scout cves <image>` |
| View logs | `docker logs <container>` |
| Copy file from container | `docker cp <container>:/path/file ./local` |

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Single-stage Dockerfile with full OS | Multi-stage + distroless/alpine |
| `COPY . .` before `npm install` | COPY package files first, then `npm ci`, then source |
| `latest` tag | Pin semantic version |
| Running as root | `USER nonroot` |
| Secrets in build args | `--mount=type=secret` |
| No `.dockerignore` | Add one — exclude node_modules, .git, .env |
| Multiple FROMs without names | Name each stage: `AS builder`, `AS deps`, `AS runtime` |

## Image Size Reference

| Stack | Single-stage | Multi-stage + Distroless |
|-------|-------------|-------------------------|
| Go | ~800MB | ~12-25MB (scratch) |
| Node.js | ~1.2GB | ~90-180MB |
| Python | ~1GB | ~120-200MB |
| Rust | ~1.5GB | ~20-50MB |
| Java | ~700MB | ~150-250MB |
